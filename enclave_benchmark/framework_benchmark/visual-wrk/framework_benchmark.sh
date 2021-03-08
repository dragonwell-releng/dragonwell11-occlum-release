#!/bin/bash

WORKSPACE=`pwd`

if [ $# != 3 ]; then
  echo "USAGE: args1 is duration, args2 is connections count, args3 is url address"
  exit
fi

# 1. make and install wrk
cd `dirname $0`
wget -q -c https://dragonwell.oss-cn-shanghai.aliyuncs.com/11/linux/x64/11.0.8.3-enclave/visual-wrk.tar.gz \
 -O - | tar -xz -C ./ --strip-components 1
make && make install

cd ${WORKSPACE}

# 2. collect wrk test result
duration=$1
connection=$2
url=$3

visual-wrk -c${connection} -d${duration}s ${url}