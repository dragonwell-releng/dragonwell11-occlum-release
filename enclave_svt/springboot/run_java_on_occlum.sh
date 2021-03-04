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
    new_json="$(jq '.resource_limits.user_space_size = "1400MB" |
                .resource_limits.kernel_space_heap_size="64MB" |
                .resource_limits.max_num_of_threads = 64 |
                .process.default_heap_size = "256MB" |
                .process.default_mmap_size = "1120MB" |
                .entry_points = [ "/usr/lib/jvm/enclave_svt/jre/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/enclave_svt/jre/lib/server:/usr/lib/jvm/enclave_svt/jre/lib:/usr/lib/jvm/enclave_svt/jre/../lib" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
}

build_web() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_svt image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
    mkdir -p image/usr/lib/spring
    cp ../${jar_path} image/usr/lib/spring/
    occlum build
}

run_web() {
    jar_path=./gs-messaging-stomp-websocket/complete/target/gs-messaging-stomp-websocket-0.1.0.jar
    check_file_exist ${jar_path}
    jar_file=`basename "${jar_path}"`
    init_instance
    build_web
    echo -e "occlum run JVM web app"
    occlum run /usr/lib/jvm/enclave_svt/jre/bin/java -Xmx512m -XX:-UseCompressedOops -XX:MaxMetaspaceSize=64m -Dos.name=Linux -jar /usr/lib/spring/${jar_file}
}

run_web