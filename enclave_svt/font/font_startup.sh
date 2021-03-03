#!/bin/bash

OCCLUM_IMAGE=${enclave_repo_address}
BUILD_MODE=${build_mode}

WORK_SPACE=`pwd`

cd ./enclave_svt/font

./create_java_font_app.sh

cd ${WORK_SPACE}

docker run -i --device /dev/isgx --network host --rm -v `pwd`:`pwd` -w `pwd` \
           -e BUILD_MODE=${BUILD_MODE} \
           ${OCCLUM_IMAGE} `pwd`/enclave_svt/font/run_java_font_app_internal.sh