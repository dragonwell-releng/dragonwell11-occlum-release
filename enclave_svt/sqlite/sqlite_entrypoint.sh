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

echo "create and build sqlite app"
cd ${WORK_SPACE}/enclave_svt/sqlite
./create_and_build_sqlite_app.sh

echo "run tomcat on occlum"
cd ${WORK_SPACE}/enclave_svt/sqlite
./run_sqlite_on_occlum.sh

check() {
    RESULT=`find -name sqlite.txt`
    if [[ $RESULT == "" ]];then
        echo 'sqlite svt test failed, no sqlite.txt was found'
        exit 1
    else
        FIND_FILE="sqlite.txt"
        FIND_STR="ID = 4NAME = MarkAGE = 25ADDRESS = Rich-Mond SALARY = 65000.0"
        if [ `grep -c "$FIND_STR" $FIND_FILE` -ne '0' ];then
            echo "sqlite svt test succeed"
        else
            echo 'sqlite svt test failed, sqlite.txt content is not expected'
            exit 1
        fi
    fi
}
check