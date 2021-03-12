#!/bin/bash

SKIP_BUILD=${skip_build}
LIBC=${libc}
BUILD_MODE=${build_mode}

if [ ${enclave_platform} != "Occlum" ]; then
    echo "${enclave_platform} is not Occlum platform."
    exit 1
fi

if [ ${SKIP_BUILD} == "true" ]; then
    if [ ${LIBC} == "musl" ]; then
        mv build-musl build
    else
        mv build-glibc build
    fi
else
    if [ ${LIBC} == "musl" ]; then
        ./make_alpine.sh ${BUILD_MODE}
    else
        ./make.sh ${BUILD_MODE}
    fi
fi