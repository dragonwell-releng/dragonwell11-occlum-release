#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}
OCCLUM_JAVA_PARAMETER=${occlum_java_parameter}
OCCLUM_HEAP_CONFIGURE=${occlum_heap_configure}
OCCLUM_KERNEL_HEAP_SIZE=${occlum_kernel_heap_size}
OCCLUM_MAX_THREAD_NUM=${occlum_max_thread_num}
FAST_MODE=${fast_mode}

WORK_SPACE=`pwd`

cd ./enclave_svt/font

if [ ${FAST_MODE} == "true" ]; then
    ./download_java_font_app_jar.sh
else
    ./create_java_font_app.sh
fi

cd ${WORK_SPACE}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           -e OCCLUM_JAVA_PARAMETER="${OCCLUM_JAVA_PARAMETER}" \
           -e OCCLUM_HEAP_CONFIGURE=${OCCLUM_HEAP_CONFIGURE} \
           -e OCCLUM_KERNEL_HEAP_SIZE=${OCCLUM_KERNEL_HEAP_SIZE} \
           -e OCCLUM_MAX_THREAD_NUM=${OCCLUM_MAX_THREAD_NUM} \
           -e FAST_MODE=${FAST_MODE} \
           -e OCCLUM_IMAGE=${OCCLUM_IMAGE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_svt/font/run_java_font_app_internal.sh