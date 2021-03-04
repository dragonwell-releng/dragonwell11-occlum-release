#!/bin/bash
set -e

JDK_PATH="/usr/lib/jvm/enclave_svt/jre"

# 1. Install mvn
apt-get update
apt-get -y install maven

# 2. Download the demo
rm -rf netty-demo && mkdir netty-demo && cd $_
git clone https://github.com/jooby-project/hello-netty.git .
git reset 32058d4dafe1edad78ef3f190eb597d6012a1d26

# 3. Build the Fat JAR file with Maven
export LD_LIBRARY_PATH=/opt/occlum/toolchains/gcc/x86_64-linux-musl/lib
export JAVA_HOME=${JDK_PATH}
mvn -q clean package