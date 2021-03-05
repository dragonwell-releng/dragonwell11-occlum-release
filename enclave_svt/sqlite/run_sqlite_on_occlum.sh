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

build_sqlite() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_svt image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
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
    echo -e "occlum run JVM tomcat app"
    occlum run /usr/lib/jvm/enclave_svt/jre/bin/java -classpath ".:sqlite-jdbc-3.6.7.jar" -Xmx512m -XX:-UseCompressedOops -XX:MaxMetaspaceSize=64m -Dos.name=Linux /usr/lib/sqlite/${class_file}
}

run_sqlite