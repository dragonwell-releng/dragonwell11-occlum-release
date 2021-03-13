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
                .entry_points = [ "/usr/lib/jvm/enclave_svt/jre/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/enclave_svt/jre/lib/server:/usr/lib/jvm/enclave_svt/jre/lib:/usr/lib/jvm/enclave_svt/jre/../lib" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
}

build_sqlite() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_svt image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
    cp /lib/x86_64-linux-gnu/libz.so.1.* image/opt/occlum/glibc/lib
    mv image/opt/occlum/glibc/lib/libz.so.1.* image/opt/occlum/glibc/lib/libz.so.1
    cp /lib/x86_64-linux-gnu/libdl-*.so image/opt/occlum/glibc/lib
    mv image/opt/occlum/glibc/lib/libdl-*.so image/opt/occlum/glibc/lib/libdl.so.2
    mkdir -p image/usr/lib/sqlite
    cp ../${jar_path} image/usr/lib/sqlite/
    cp ../${class_path} image/usr/lib/sqlite/
    occlum build
}

run_sqlite() {
    class_path=./sqlite-demo/SQLiteJDBC.class
    jar_path=./sqlite-demo/sqlite-jdbc-3.6.7.jar
    check_file_exist ${class_path}
    check_file_exist ${jar_path}
    class_file=`basename "${class_path}"`
    class_file=$(echo $class_file | cut -d . -f1)
    init_instance
    build_sqlite
    echo -e "occlum run JVM sqlite app"
    occlum run /usr/lib/jvm/enclave_svt/jre/bin/java -classpath /usr/lib/sqlite:/usr/lib/sqlite/sqlite-jdbc-3.6.7.jar ${OCCLUM_JAVA_PARAMETER} ${class_file}
}

run_sqlite