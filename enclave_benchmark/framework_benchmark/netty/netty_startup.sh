#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}
DURATION=${duration}
CONNECTIONS=${connections}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           -e DURATION=${DURATION} \
           -e CONNECTIONS=${CONNECTIONS} \
           ${OCCLUM_IMAGE} `pwd`/enclave_benchmark/framework_benchmark/netty/netty_entrypoint.sh