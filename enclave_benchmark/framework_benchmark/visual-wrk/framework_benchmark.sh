#!/bin/bash

WORKSPACE=`pwd`

if [ $# != 4 ]; then
  echo "USAGE: args1 is duration, args2 is connections count, arg3 is wrk thread num, args4 is url address"
  exit
fi

# 1. download visual-wrk
cd `dirname $0`
wget -q -c https://dragonwell.oss-cn-shanghai.aliyuncs.com/11/linux/x64/11.0.8.3-enclave/visual-wrk.tar.gz \
 -O - | tar -xz -C ./ --strip-components 1
make && make install
# wget -q https://dragonwell.oss-cn-shanghai.aliyuncs.com/11/linux/x64/11.0.8.3-enclave/visual-wrk
# chmod 777 visual-wrk
cd ${WORKSPACE}

# 2. collect wrk test result
duration=$1
connection=$2
thread_num=$3
url=$4

visual-wrk -c${connection} -d${duration}s ${url}