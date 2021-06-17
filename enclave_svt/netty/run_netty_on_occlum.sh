#!/bin/bash
set -e

JDK_PATH="/usr/lib/jvm/enclave_svt/jre"

check_file_exist() {
    file=$1
    if [ ! -f ${file} ];then
        echo "Error: cannot stat file '${file}'"
        echo "Please see README and build it"
        exit 1
    fi
}

init_instance() {
    # Init Occlum instance
    rm -rf occlum_instance && mkdir occlum_instance
    /opt/occlum/start_aesm.sh
    cd occlum_instance
    occlum init
    default_mmap_size=${PROCESS_MMAP_SIZE}
    occlum_kernel_heap_size=${OCCLUM_KERNEL_HEAP_SIZE}"MB"
    occlum_max_thread_num=${OCCLUM_MAX_THREAD_NUM}
    user_space_size=${OCCLUM_USER_SPACE}
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
                .entry_points = [ "/usr/lib/jvm/enclave_svt/jre/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/enclave_svt/jre/lib/server:/usr/lib/jvm/enclave_svt/jre/lib:/usr/lib/jvm/enclave_svt/jre/../lib" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
}

build_netty() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_svt image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
    os_name="centos"
    result=$(echo ${OCCLUM_IMAGE} | grep "${os_name}")
    # centos
    if [[ "$result" != "" ]]; then
        cp /usr/lib64/libz.so.1.* image/opt/occlum/glibc/lib
        mv image/opt/occlum/glibc/lib/libz.so.1.* image/opt/occlum/glibc/lib/libz.so.1
        cp /opt/occlum/glibc/lib/libdl.so.2 image/opt/occlum/glibc/lib
        cp /opt/occlum/glibc/lib/librt.so.1 image/opt/occlum/glibc/lib
        cp /opt/occlum/glibc/lib/libm.so.6 image/opt/occlum/glibc/lib
        cp /opt/occlum/glibc/lib/libnss_files.so.2 image/opt/occlum/glibc/lib
    else
        cp /lib/x86_64-linux-gnu/libz.so.1.* image/opt/occlum/glibc/lib
        mv image/opt/occlum/glibc/lib/libz.so.1.* image/opt/occlum/glibc/lib/libz.so.1
        cp /lib/x86_64-linux-gnu/libdl-*.so image/opt/occlum/glibc/lib
        mv image/opt/occlum/glibc/lib/libdl-*.so image/opt/occlum/glibc/lib/libdl.so.2
    fi

    mkdir -p image/usr/lib/netty
    cp ../${jar_path} image/usr/lib/netty/
    occlum build
}

run_netty() {
    jar_path=./netty-demo/target/hello-netty-1.0.jar
    check_file_exist ${jar_path}
    jar_file=`basename "${jar_path}"`
    init_instance
    build_netty
    echo -e "occlum run JVM netty app"
    occlum run /usr/lib/jvm/enclave_svt/jre/bin/java ${OCCLUM_JAVA_PARAMETER} -jar /usr/lib/netty/${jar_file}
}

run_netty