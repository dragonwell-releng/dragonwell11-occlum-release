#!/bin/bash

SHAREPATH=`pwd`

init_instance() {
    # Init Occlum instance
    rm -rf occlum_instance && mkdir occlum_instance
    cd occlum_instance
    occlum init
    default_mmap_size=${OCCLUM_HEAP_CONFIGURE}
    occlum_kernel_heap_size=${OCCLUM_KERNEL_HEAP_SIZE}"MB"
    occlum_max_thread_num=${OCCLUM_MAX_THREAD_NUM}
    user_space_size=`expr ${default_mmap_size} + 200`
    default_mmap_size=${default_mmap_size}"MB"
    user_space_size=${user_space_size}"MB"
    new_json="$(jq --arg default_mmap_size "$default_mmap_size" \
                 --arg user_space_size "$user_space_size" \
                 --arg occlum_kernel_heap_size "$occlum_kernel_heap_size" \
                 --argjson occlum_max_thread_num "$occlum_max_thread_num" \
               '.resource_limits.user_space_size = $user_space_size |
                .resource_limits.kernel_space_heap_size = $occlum_kernel_heap_size |
                .resource_limits.max_num_of_threads = $occlum_max_thread_num |
                .process.default_heap_size = "150MB" |
                .process.default_mmap_size = $default_mmap_size |
                .entry_points = [ "/usr/lib/jvm/jdk/jre/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/jdk/jre/lib/server:/usr/lib/jvm/jdk/jre/lib:/usr/lib/jvm/jdk/jre/../lib" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
    cp -r $SHAREPATH/occlum_ut.tar.gz ./ && tar -zxf occlum_ut.tar.gz
}

build_dragonwell_ut() {
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib

    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r ./occlum_ut/usr/lib/jvm/jdk image/usr/lib/jvm

    # fix new work issue
    echo '127.0.0.1   occlum-node' >> image/etc/hosts

    mkdir -p image/usr/jvm/
    cp -r ./occlum_ut/usr/jvm/jtreg image/usr/jvm && cp -r ./occlum_ut/usr/jvm/test image/usr/jvm
    sed -i 's/$(SECURE_IMAGE): $(IMAGE) $(IMAGE_DIRS) $(IMAGE_FILES)/$(SECURE_IMAGE):/' /opt/occlum/build/bin/occlum_build.mk
    occlum build
}

run_dragonwell_ut() {
    /opt/occlum/start_aesm.sh
    init_instance
    build_dragonwell_ut
    $SHAREPATH/dragonwell-enclave-ut.py /usr/jvm/test/JTwork
}

# install xlrd and xlwt for python3
apt-get update
apt-get -y install python3-pip
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pandas
# run dragonwell ut
run_dragonwell_ut
