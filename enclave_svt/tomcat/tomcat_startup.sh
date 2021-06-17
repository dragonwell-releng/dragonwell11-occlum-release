#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}
OCCLUM_JAVA_PARAMETER=${occlum_java_parameter}
PROCESS_MMAP_SIZE=${process_mmap_size}
OCCLUM_USER_SPACE=${OCCLUM_USER_SPACE}
OCCLUM_KERNEL_HEAP_SIZE=${occlum_kernel_heap_size}
OCCLUM_MAX_THREAD_NUM=${occlum_max_thread_num}
FAST_MODE=${fast_mode}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           -e OCCLUM_JAVA_PARAMETER="${OCCLUM_JAVA_PARAMETER}" \
           -e PROCESS_MMAP_SIZE=${PROCESS_MMAP_SIZE} \
           -e OCCLUM_USER_SPACE=4{OCCLUM_USER_SPACE} \
           -e OCCLUM_KERNEL_HEAP_SIZE=${OCCLUM_KERNEL_HEAP_SIZE} \
           -e OCCLUM_MAX_THREAD_NUM=${OCCLUM_MAX_THREAD_NUM} \
           -e FAST_MODE=${FAST_MODE} \
           -e OCCLUM_IMAGE=${OCCLUM_IMAGE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_svt/tomcat/tomcat_entrypoint.sh