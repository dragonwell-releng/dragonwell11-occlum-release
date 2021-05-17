#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}
DURATION=${duration}
CONNECTIONS=${connections}
WRK_THREAD_NUM=${wrk_thread_num}
OCCLUM_JAVA_PARAMETER=${occlum_java_parameter}
OCCLUM_HEAP_CONFIGURE=${occlum_heap_configure}
OCCLUM_KERNEL_HEAP_SIZE=${occlum_kernel_heap_size}
OCCLUM_MAX_THREAD_NUM=${occlum_max_thread_num}
FAST_MODE=${fast_mode}
SGX_MODE=${sgx_mode}

sgx_parameter="--device /dev/isgx"
if [ ${SGX_MODE} == "sgx2" ]; then
    sgx_parameter="--privileged -v /dev/sgx_enclave:/dev/sgx/enclave -v /dev/sgx_provision:/dev/sgx/provision -v /var/run/aesmd:/var/run/aesmd"
fi

docker run -i ${sgx_parameter} --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           -e DURATION=${DURATION} \
           -e CONNECTIONS=${CONNECTIONS} \
           -e WRK_THREAD_NUM=${WRK_THREAD_NUM} \
           -e OCCLUM_JAVA_PARAMETER="${OCCLUM_JAVA_PARAMETER}" \
           -e OCCLUM_HEAP_CONFIGURE=${OCCLUM_HEAP_CONFIGURE} \
           -e OCCLUM_KERNEL_HEAP_SIZE=${OCCLUM_KERNEL_HEAP_SIZE} \
           -e OCCLUM_MAX_THREAD_NUM=${OCCLUM_MAX_THREAD_NUM} \
           -e FAST_MODE=${FAST_MODE} \
           -e OCCLUM_IMAGE=${OCCLUM_IMAGE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_benchmark/framework_benchmark/tomcat/tomcat_entrypoint.sh