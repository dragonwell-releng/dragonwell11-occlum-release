#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_svt/sqlite/sqlite_entrypoint.sh