#!/bin/bash

set -e

JDK_PATH="/usr/lib/jvm/enclave_svt/jre"

# 1. Create the sqlite demo
rm -rf sqlite-demo && mkdir sqlite-demo && cd $_
cp ../SQLiteJDBC.java ./

# 2. download sqlite.jar
wget -q https://dragonwell.oss-cn-shanghai.aliyuncs.com/11/linux/x64/11.0.8.3-enclave/sqlite-jdbc-3.6.7.jar

# 3. build sqlite app
export LD_LIBRARY_PATH=/opt/occlum/toolchains/gcc/x86_64-linux-musl/lib
export JAVA_HOME=${JDK_PATH}
${JDK_PATH}/bin/javac SQLiteJDBC.java