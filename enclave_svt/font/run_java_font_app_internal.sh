#!/bin/bash
set -e

JDK_PATH="/usr/lib/jvm/enclave_svt/jre"
BUILD_MODE=${BUILD_MODE}
JDK_IMAGES_DIR=""

case "$BUILD_MODE" in
    release)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-release/images/jdk
    ;;
    debug)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-slowdebug/images/jdk
    ;;
    fastdebug)
        JDK_IMAGES_DIR=build/linux-x86_64-normal-server-fastdebug/images/jdk
    ;;
    *)
        echo "build mode must be release or debug or fastdebug!"
        exit 1
    ;;
esac

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

build_poi_font() {
    # Copy JVM and JAR file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/enclave_svt image/usr/lib/jvm
    cp /usr/local/occlum/x86_64-linux-musl/lib/libz.so.1 image/lib
    cp /lib/x86_64-linux-gnu/libz.so.1.* image/opt/occlum/glibc/lib
    mv image/opt/occlum/glibc/lib/libz.so.1.* image/opt/occlum/glibc/lib/libz.so.1
    cp /lib/x86_64-linux-gnu/libdl-*.so image/opt/occlum/glibc/lib
    mv image/opt/occlum/glibc/lib/libdl-*.so image/opt/occlum/glibc/lib/libdl.so.2
    cp -r /opt/occlum/font-lib/etc image && cp -r /opt/occlum/font-lib/lib/. image/lib && cp -r /opt/occlum/font-lib/usr/. image/usr
    mkdir -p image/usr/app
    cp ../${jar_path} image/usr/app
    occlum build
}

run_poi_font() {
    jar_path=./poi-excel-demo/build/libs/SXSSFWriteDemoTwo.jar
    check_file_exist ${jar_path}
    jar_file=`basename "${jar_path}"`
    cp -r ./font-lib /opt/occlum
    init_instance
    build_poi_font
    echo -e "occlum run JVM poi font app"
    occlum run /usr/lib/jvm/enclave_svt/jre/bin/java ${OCCLUM_JAVA_PARAMETER} -jar /usr/app/SXSSFWriteDemoTwo.jar
}

check() {
    RESULT=`find -name Demo.xlsx`
    if [[ $RESULT == "" ]];then
        echo 'font svt test failed'
        exit 1
    else
        echo 'font svt test succeed'
    fi
}

mkdir -p ${JDK_PATH}
cp -r ./${JDK_IMAGES_DIR}/. ${JDK_PATH}

cd `pwd`/enclave_svt/font

run_poi_font
check