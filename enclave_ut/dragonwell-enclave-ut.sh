#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}

UT_MAX_DURATION=${ut_max_duration}
UT_RETRY_TIMES=${ut_retry_times}
OCCLUM_JAVA_PARAMETER=${occlum_java_parameter}
OCCLUM_HEAP_CONFIGURE=${occlum_heap_configure}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd`/enclave_ut \
           -e UT_MAX_DURATION=${UT_MAX_DURATION} \
           -e UT_RETRY_TIMES=${UT_RETRY_TIMES} \
           -e OCCLUM_JAVA_PARAMETER="${OCCLUM_JAVA_PARAMETER}" \
           -e OCCLUM_HEAP_CONFIGURE=${OCCLUM_HEAP_CONFIGURE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_ut/dragonwell-enclave-ut-internal.sh
