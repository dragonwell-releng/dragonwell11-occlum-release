#!/usr/bin/env python3

# This script must embed in occlum_instance document
# Import the os module, for the os.walk function
import os
import sys
import re
import time
import signal
import codecs
import tempfile
import subprocess
import dragonwell_enclave_ut_csv
from enum import Enum

sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

time_duration = int(os.getenv("UT_MAX_DURATION")) * 60
ut_time_expire = time_duration
occlum_start_expire = time_duration
occlum_stop_expire = time_duration
timeout_retry_time = int(os.getenv("UT_RETRY_TIMES"))

#occlum_java_default_parameter="-Xmx800m -XX:MaxMetaspaceSize=256m -XX:-UseCompressedOops -Dos.name=Linux"
occlum_java_default_parameter = os.getenv("OCCLUM_JAVA_PARAMETER")

class Status(Enum):
    Initial = 0
    TimeoutExpired = 1
    CalledProcessError = 2
    ExceptionError = 3
    JtrParseFailed = 4
    Normal = 5

occlum_server_name="occlum_exec_ser"
occlum_client_name="occlum_exec_cli"

now = time.strftime("%Y-%m-%d-%H_%M_%S",time.localtime(time.time()))
csv_path = now + r".csv"
title_value = ["Unit Test Case", "Normal Result", "Enclave Result", "Details Info"]

JTwork_path = sys.argv[1]
Image_JTwork_path = "./image" + JTwork_path

# Parse CLASSPATH and java cmd contect
pattern1=r"CLASSPATH=(.*?)\nresult:\s(.*?)\."
# Parse test path
pattern2=r"\$root=(.*?)\/test\/"
# Parse jtreg path
pattern3=r"javatest.jar:(.*?)\/lib\/jtreg.jar\s"
# Parse JTwork path
pattern4=r"^(.*?)\/JTwork\/classes\/"
# Parse jdk path
pattern5=r"-Dtest.jdk=(.*?)\s"
# Parse ut result
pattern6=r"STATUS:(.*?)\."
# Parse ut details and Error code, gs mode
pattern7=r"^(.*)\nError: (.*?)$"

normal_ut_total_count = 0
normal_ut_passed_count = 0
occlum_ut_total_count = 0
occlum_ut_passed_count = 0

# limit ut max number for debug
debug_limited_max_ut_count = 0xFFFFFFFF

def debug_limited_max_ut_func():
    global debug_limited_max_ut_count
    global occlum_ut_total_count
    if debug_limited_max_ut_count < occlum_ut_total_count:
        return True
    return False

def occlum_service_shutdown_forcely():
    # check there is already occlum server and client process, if yes kill it forcely
    os.environ['occlum_server_name']=str(occlum_server_name)
    os.environ['occlum_client_name']=str(occlum_client_name)
    os.system("pkill -9 $occlum_server_name && pkill -9 $occlum_client_name")

def occlum_start_asyn():
    occlum_service_shutdown_forcely()
    try:
        result = subprocess.run("exec occlum start", shell=True, timeout=occlum_start_expire)
    except subprocess.TimeoutExpired:
        print("occlum start timeout expired, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    except subprocess.CalledProcessError as e:
        e = e
        print("occlum start subprocess.CalledProcessError, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    except Exception:
        print("occlum start exception, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    else:
        print("occlum start normally: ", result)

def occlum_stop_asyn():
    try:
        result = subprocess.run("exec occlum stop", shell=True, timeout=occlum_stop_expire)
    except subprocess.TimeoutExpired:
        print("occlum stop timeout expired, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    except subprocess.CalledProcessError as e:
        e = e
        print("occlum stop subprocess.CalledProcessError, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    except Exception:
        print("occlum stop exception, so shutdown all occlum service forcely: ", result)
        occlum_service_shutdown_forcely()
    else:
        print("occlum stop normally: ", result)

def occlum_exec_ut(args, timeout, retry_time):

    def get_context(fd):
        fd.seek(0)
        result = fd.read().decode('utf-8')
        fd.close()
        occlum_stop_asyn()
        occlum_start_asyn()
        return result

    def ut_result_parse(context, status):
        # result[0] is ut result;
        # result[1] is ut details;
        # result[2] is ut ERROR code;
        result = ["", "", ""]

        for sub_ut_result in re.finditer(pattern6, context):
            result[0] = sub_ut_result.group(1)

        for sub_details_and_error in re.finditer(pattern7, context, re.S):
            result[1] = sub_details_and_error.group(1)
            result[2] = sub_details_and_error.group(2)

        if status == Status.Normal:
            if len(result[0]) == 0:
                result[0] = "Failed"
        else:
            result[0] = status.name
            result[1] = context

        print("occlum exec status: " + status.name)
        return result

    context = ""
    status = Status.Initial
    for i in range(retry_time):
        # init_stdout direct output to console
        try:
            fd = tempfile.NamedTemporaryFile()
            result = subprocess.run(args, shell=True, timeout=timeout, stderr=subprocess.STDOUT, stdout=fd)
            status = Status.Initial
        except subprocess.TimeoutExpired:
            print("occlum exec result: ", result)
            status = Status.TimeoutExpired
            context = get_context(fd)
        except subprocess.CalledProcessError:
            print("occlum exec result: ", result)
            status = Status.CalledProcessError
            context = get_context(fd)
        except Exception:
            print("occlum exec result: ", result)
            status = Status.ExceptionError
            context = get_context(fd)
        else:
            print("occlum exec result: ", result)
            status = Status.Normal
            fd.seek(0)
            context = fd.read().decode('utf-8')
            fd.close()
            break

    return ut_result_parse(context, status)

def parse_jtr_and_run_ut(jtr_path):

    global normal_ut_total_count
    global normal_ut_passed_count
    global occlum_ut_total_count
    global occlum_ut_passed_count

    f = open(jtr_path)
    context = f.read()

    # get ut java file's full name
    java_ut_path = jtr_path[len(Image_JTwork_path)+len("/"):].replace(".jtr",".java")

    java_jtreg_run = re.finditer(pattern1, context, re.S)
    if java_jtreg_run is None:
        print(jtr_path + " could not parse ut <java run context>")
        row = [java_ut_path, Status.JtrParseFailed.name, Status.JtrParseFailed.name, ""]
        normal_ut_total_count = normal_ut_total_count + 1
        dragonwell_enclave_ut_csv.write_csv(csv_path, row)
        return

    for sub_java_jtreg_run in java_jtreg_run:
        # first step, parse classpath and java parameters
        tmp_java_jtreg_run = sub_java_jtreg_run.group(1)
        # parse ut result run in normal environment
        tmp_java_normal_ut_result = sub_java_jtreg_run.group(2)
        tmp_java_jtreg_run = tmp_java_jtreg_run.replace("\\", "")
        tmp_java_jtreg_run = tmp_java_jtreg_run.replace("\n", "")
        tmp_java_jtreg_run_split = " ".join(re.split("\s+", tmp_java_jtreg_run, flags=re.UNICODE)).split()
        tmp_java_jtreg_run_split[0], tmp_java_jtreg_run_split[1] = tmp_java_jtreg_run_split[1], tmp_java_jtreg_run_split[0]

        # if a parameter was set twice, the second is applicable.
        tmp_java_jtreg_run_split[1] = occlum_java_default_parameter + " -cp " + tmp_java_jtreg_run_split[1]
        occlum_java_cmd = " ".join(tmp_java_jtreg_run_split)
        args = "exec occlum exec " + occlum_java_cmd
        occlum_ut_result = occlum_exec_ut(args, ut_time_expire, timeout_retry_time)

        # write to .csv file
        row = [java_ut_path, tmp_java_normal_ut_result, occlum_ut_result[0], occlum_ut_result[1]]
        print(java_ut_path + '\n' + occlum_ut_result[1] + '\n')
        dragonwell_enclave_ut_csv.write_csv(csv_path, row)

        occlum_ut_total_count = occlum_ut_total_count + 1
        normal_ut_total_count = normal_ut_total_count + 1
        if tmp_java_normal_ut_result == "Passed":
            normal_ut_passed_count = normal_ut_passed_count + 1
        if occlum_ut_result[0] == "Passed":
            occlum_ut_passed_count = occlum_ut_passed_count + 1
    return

def recurse_parse_jtr():
    # parse jtr and run ut in enclave
    for file_path, dir_list, file_list in os.walk(Image_JTwork_path):
       dir_list = dir_list
       for file_name in file_list:
            full_path = os.path.join(file_path, file_name)
            if full_path.endswith(".jtr"):
                parse_jtr_and_run_ut(full_path)
                if debug_limited_max_ut_func():
                    return

def occlum_start_ut():
    # Start occlum in exec mode.
    print("**********************occlum start ut**********************")
    occlum_start_asyn()

    # create enclave ut .csv file
    dragonwell_enclave_ut_csv.create_csv(csv_path, title_value)
    # insert a placehold as statistic info at the first row
    first_row = ["Total UT Statistic:", "%()", "%()", "%: UT Passed Rate, (): UT Total Statistic Count"]
    dragonwell_enclave_ut_csv.write_csv(csv_path, first_row)

    recurse_parse_jtr()

    if (normal_ut_total_count == 0 or occlum_ut_total_count == 0):
        if (normal_ut_total_count == 0):
            first_row[1] = '{:.2%}'.format(0) + '(' + str(normal_ut_total_count) + ')'
        if (occlum_ut_total_count == 0):
            first_row[2] = '{:.2%}'.format(0) + '(' + str(occlum_ut_total_count) + ')'
    else:
        first_row[1] = '{:.2%}'.format(normal_ut_passed_count/normal_ut_total_count) + '(' + str(normal_ut_total_count) + ')'
        first_row[2] = '{:.2%}'.format(occlum_ut_passed_count/occlum_ut_total_count) + '(' + str(occlum_ut_total_count) + ')'

    dragonwell_enclave_ut_csv.update_total_statistic_data(csv_path, first_row, 0)
    # convert .csv file to .html file
    dragonwell_enclave_ut_csv.convert_csv_to_html(csv_path, title_value[3])

    print("**********************occlum stop**********************")
    occlum_stop_asyn()

#occlum start to process java ut.
occlum_start_ut()
