#!/bin/bash
set -e

JDK_PATH="/usr/lib/jvm/enclave_benchmark/jre"

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
                .entry_points = [ "/usr/lib/jvm/enclave_benchmark/jre/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/enclave_benchmark/jre/lib/server:/usr/lib/jvm/enclave_benchmark/jre/lib:/usr/lib/jvm/enclave_benchmark/jre/../lib" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
}

build_tomcat() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_benchmark/ image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
    mkdir -p image/usr/lib/tomcat
    cp ../${jar_path} image/usr/lib/tomcat/
    occlum build
}

run_tomcat() {
    jar_path=./tomcat-demo/target/employees-app-1.0-SNAPSHOT-jar-with-dependencies.jar
    check_file_exist ${jar_path}
    jar_file=`basename "${jar_path}"`
    init_instance
    build_tomcat
    echo -e "occlum run JVM tomcat app"
    occlum run /usr/lib/jvm/enclave_benchmark/jre/bin/java ${OCCLUM_JAVA_PARAMETER} -jar /usr/lib/tomcat/${jar_file}
}

run_tomcat