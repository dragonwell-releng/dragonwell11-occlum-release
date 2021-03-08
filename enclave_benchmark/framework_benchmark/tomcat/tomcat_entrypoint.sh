#!/bin/bash

WORK_SPACE=`pwd`
BUILD_MODE=${BUILD_MODE}
JDK_IMAGES_DIR=""
JDK_PATH="/usr/lib/jvm/enclave_benchmark/jre"

DURATION=${DURATION}
CONNECTIONS=${CONNECTIONS}

case "$BUILD_MODE" in
    release)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-release/images/jdk
    ;;
    debug)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-slowdebug/images/jdk
    ;;
    fastdebug)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-fastdebug/images/jdk
    ;;
    *)
        echo "build mode must be release or debug or fastdebug!"
        exit 1
    ;;
esac

mkdir -p ${JDK_PATH}
cp -r ./${JDK_IMAGES_DIR}/. ${JDK_PATH}

echo "create and build tomcat app"
cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat
./create_and_build_tomcat_app.sh

echo "run tomcat on occlum"
cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat
./run_tomcat_on_occlum.sh &

echo "waiting for tomcat start up for three minitutes......"
sleep 90

RESULT=""
Count=20
while [[ $RESULT == "" && $Count -gt 1 ]]; do
    RESULT=$(curl -v http://127.0.0.1:8080/employee)
    Count=`expr $Count - 1`
    sleep 5
    echo "wait more five seconds"
done

if [[ $Count -gt 1 ]];then
    echo "tomcat svt test succeed, now let's benchmark it"
    echo $RESULT
    cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/visual-wrk/framework_benchmark.sh \
    ${DURATION} ${CONNECTIONS} "http://127.0.0.1:8080/employee"
    mkdir -p ${WORK_SPACE}/enclave_benchmark/framework_benchmark/report
    mv ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat/report/log.html \
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat/report/tomcat.html
    cp -rf -n ${WORK_SPACE}/enclave_benchmark/framework_benchmark/tomcat/report/. \
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/report
else
    echo 'tomcat svt test failed'
    exit 1
fi