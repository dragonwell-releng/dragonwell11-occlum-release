#!/bin/bash
set -e

JDK_PATH="/usr/lib/jvm/enclave_benchmark/jre"

# 1. Download the demo
rm -rf gs-messaging-stomp-websocket && mkdir gs-messaging-stomp-websocket
cd gs-messaging-stomp-websocket
# git clone https://github.com/spring-guides/gs-messaging-stomp-websocket.git .
git clone https://gitee.com/feng520han/gs-messaging-stomp-websocket.git .
git checkout -b 2.1.6.RELEASE tags/2.1.6.RELEASE

# 2. Build the Fat JAR file with Maven
cd complete
export LD_LIBRARY_PATH=/opt/occlum/toolchains/gcc/x86_64-linux-musl/lib
export JAVA_HOME=${JDK_PATH}
./mvnw -q clean package
