#!/bin/bash

if [ ${LIBC} == "musl" ]; then
    apk --no-cache add wget
fi

WORK_SPACE=`pwd`
BUILD_MODE=${BUILD_MODE}
JTREG_DOWNLOAD=${JTREG_DOWNLOAD}
JTREG_PATH=${JTREG_PATH}
TEST_PATH=${TEST_PATH}
JDK_PATH=${JDK_PATH}
TEST_SET=${TEST_SET}
JDK_IMAGES_DIR=""

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
        echo "Argument must be release or debug or fastdebug!"
        exit 1
    ;;
esac

mkdir -p $JTREG_PATH && cd $_
wget -q -c $JTREG_DOWNLOAD -O - | tar -xz --strip-components 1

mkdir -p $TEST_PATH && cd $_
cp -r $WORK_SPACE/test/. ./

mkdir -p $JDK_PATH && cd $_
cp -r $WORK_SPACE/$JDK_IMAGES_DIR/. ./

cd $TEST_PATH
echo 'start to jtreg ut......'
array=(${TEST_SET//\\n/ })
for var in ${array[@]}
do
   echo "jtreg ut set path: $var"
   $JTREG_PATH/bin/jtreg -esa -v:time -jdk:$JDK_PATH $TEST_PATH/$var
done

mkdir -p $WORK_SPACE/enclave_ut/occlum_ut/$JTREG_PATH && cd $_
cp -r $JTREG_PATH/. ./

mkdir -p $WORK_SPACE/enclave_ut/occlum_ut/$TEST_PATH && cd $_
cp -r $TEST_PATH/. ./

mkdir -p $WORK_SPACE/enclave_ut/occlum_ut/$JDK_PATH && cd $_
cp -r $JDK_PATH/. ./

cd $WORK_SPACE/enclave_ut
tar -zcf occlum_ut.tar.gz occlum_ut
