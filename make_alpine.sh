#!/bin/bash

if [ $# != 1 ]; then
  echo "USAGE: $0 release/debug/fastdebug"
  exit
fi

# incr by every Dragonwell release
BUILD_MODE=$1
BUILD_NUMBER=""
# DOCKER_IMAGE=registry.cn-hangzhou.aliyuncs.com/dragonwell/dragonwell11-build-musl:v1
# DOCKER_IMAGE=adoptopenjdk/alpine3_build_image:latest
IMAGE_EXIST=`docker images | grep 57de0a70e364`
if [ IMAGE_EXIST == "" ]; then
    DOCKER_IMAGE=https://dragonwell.oss-cn-shanghai.aliyuncs.com/11/linux/x64/11.0.8.3-enclave/dragonwell11-alpine-build.tar
    mkdir -p docker_image && cd $_
    wget -c $DOCKER_IMAGE
    docker load < dragonwell11-alpine-build.tar
    cd ..
fi

DOCKER_IMAGE=57de0a70e364
SCRIPT_NAME=build_alpine_entrypoint.sh

case "${BUILD_MODE}" in
    release)
        DEBUG_LEVEL="release"
    ;;
    debug)
        DEBUG_LEVEL="slowdebug"
    ;;
    fastdebug)
        DEBUG_LEVEL="fastdebug"
    ;;
    *)
        echo "Argument must be release or debug or fastdebug!"
        exit 1
    ;;
esac

NEW_JAVA_HOME=${JDK_IMAGES_DIR}/jdk

if [ "x${BUILD_NUMBER}" = "x" ]; then
  BUILD_NUMBER=0
fi

ps -e | grep docker
if [ $? -eq 0 ]; then
    echo "We will build DragonWell11 for Alpine in Docker!"
    docker pull $DOCKER_IMAGE
    docker run -i --rm -e BUILD_NUMBER=$BUILD_NUMBER -e DEBUG_LEVEL=$DEBUG_LEVEL \
                    -e BUILD_MODE=$BUILD_MODE -v `pwd`:`pwd` -w `pwd` --entrypoint=bash \
                    $DOCKER_IMAGE `pwd`/$SCRIPT_NAME
    exit $?
fi

rm -rf docker_image
