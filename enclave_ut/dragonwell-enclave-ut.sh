#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}

UT_MAX_DURATION=${ut_max_duration}
UT_RETRY_TIMES=${ut_retry_times}
OCCLUM_JAVA_PARAMETER=${occlum_java_parameter}
PROCESS_MMAP_SIZE=${process_mmap_size}
OCCLUM_USER_SPACE=${occlum_user_space}
OCCLUM_KERNEL_HEAP_SIZE=${occlum_kernel_heap_size}
OCCLUM_MAX_THREAD_NUM=${occlum_max_thread_num}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd`/enclave_ut \
           -e UT_MAX_DURATION=${UT_MAX_DURATION} \
           -e UT_RETRY_TIMES=${UT_RETRY_TIMES} \
           -e OCCLUM_JAVA_PARAMETER="${OCCLUM_JAVA_PARAMETER}" \
           -e PROCESS_MMAP_SIZE=${PROCESS_MMAP_SIZE} \
           -e OCCLUM_USER_SPACE=${OCCLUM_USER_SPACE}
           -e OCCLUM_KERNEL_HEAP_SIZE=${OCCLUM_KERNEL_HEAP_SIZE} \
           -e OCCLUM_MAX_THREAD_NUM=${OCCLUM_MAX_THREAD_NUM} \
           -e OCCLUM_IMAGE=${OCCLUM_IMAGE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_ut/dragonwell-enclave-ut-internal.sh
