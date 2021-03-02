#!/bin/bash

#wget alpine jdk11 as boot jdk for compile
BOOT_JDK=https://cdn.azul.com/zulu/bin/zulu11.45.27-ca-jdk11.0.10-linux_musl_x64.tar.gz
mkdir -p boot_jdk && cd $_
wget -q -c $BOOT_JDK -O - | tar -xz --strip-components 1
export JAVA_HOME=`pwd`
cd ..

bash configure --disable-warnings-as-errors

make CONF=$BUILD_MODE LOG=cmdlines JOBS=8 images

rm -rf boot_jdk