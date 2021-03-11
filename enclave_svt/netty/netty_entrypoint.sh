#!/bin/bash

WORK_SPACE=`pwd`
BUILD_MODE=${BUILD_MODE}
JDK_IMAGES_DIR=""
JDK_PATH="/usr/lib/jvm/enclave_svt/jre"

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

if [ ${FAST_MODE} == "true" ]; then
    cd ${WORK_SPACE}/enclave_svt/netty
    ./download_java_netty_app_jar.sh
else
    echo "download and build netty app"
    cd ${WORK_SPACE}/enclave_svt/netty
    ./download_and_build_netty_app.sh
fi

echo "run java on occlum"
cd ${WORK_SPACE}/enclave_svt/netty
./run_netty_on_occlum.sh &

echo "waiting for netty start up for three minitutes......"
sleep 90

RESULT=""
Count=20
while [[ $RESULT == "" && $Count -gt 1 ]]; do
    RESULT=$(curl http://127.0.0.1:8080/)
    Count=`expr $Count - 1`
    sleep 5
    echo "wait more five seconds"
done

if [[ $Count -gt 1 ]];then
    echo 'netty svt test succeed'
    echo $RESULT
else
    echo 'netty svt test failed'
    exit 1
fi