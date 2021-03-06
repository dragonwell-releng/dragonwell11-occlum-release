#!/bin/bash

for file in $(ls ./occlum_instance)
do
    if [ "${file##*.}" = "html" ]; then
        cp ./occlum_instance/${file} ./occlum_instance/enclave_ut_report.html
        break
    fi
done
