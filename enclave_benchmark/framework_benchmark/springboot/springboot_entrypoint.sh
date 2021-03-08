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

echo "download and build web app"
cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot
./download_and_build_web_app.sh

echo "run java on occlum"
cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot
./run_java_on_occlum.sh &

echo "waiting for springboot start up for five minitutes......"
sleep 150

RESULT=""
Count=50
while [[ $RESULT == "" && $Count -gt 1 ]]; do
    RESULT=$(curl http://localhost:8080)
    Count=`expr $Count - 1`
    sleep 5
    echo "wait more five seconds"
done

if [[ $Count -gt 1 ]];then
    echo "SpringBoot svt test succeed, now let's benchmark it"
    echo $RESULT
    cd ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/visual-wrk/framework_benchmark.sh \
    ${DURATION} ${CONNECTIONS} "http://localhost:8080/"
    mkdir -p ${WORK_SPACE}/enclave_benchmark/framework_benchmark/report
    mv ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot/report/log.html \
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot/report/springboot.html
    cp -rf -n ${WORK_SPACE}/enclave_benchmark/framework_benchmark/springboot/report/. \
    ${WORK_SPACE}/enclave_benchmark/framework_benchmark/report
else
    echo 'SpringBoot svt test failed'
    exit 1
fi