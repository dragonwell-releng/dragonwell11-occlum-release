pipeline {
         agent {
             node {
                 label 'sgx-server'
                 customWorkspace '/home/data/jenkins'
             }
         }
         stages {
                 stage('Build') {
                 steps {
                     echo 'Download dragonwell resource code and build it'
                     sh "printenv"
                     sh "mkdir -p ${WORKSPACE}/workspace/${BUILD_TAG} && rm -rf ${WORKSPACE}/workspace/${BUILD_TAG}/*"
                     sh "wget -q -c ${dragonwell_repo_address} -O - | tar -xz -C ${WORKSPACE}/workspace/${BUILD_TAG} --strip-components 1"
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && \
                         mkdir tmp && git clone git@github.com:dragonwell-releng/dragonwell11-occlum-release.git ./tmp && \
                         mv ./tmp/* ./ && rm -rf tmp"
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./create_jdk_build.sh"
                 }
                 }
                 stage('SpringBoot') {
                 steps {
                     echo 'Build SpringBoot and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/springboot/springboot_startup.sh"
                 }
                 }
                 stage('Font Support') {
                 steps {
                     echo 'create font app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/font/font_startup.sh"
                 }
                 }
                 stage('Netty') {
                 steps {
                     echo 'create netty app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/netty/netty_startup.sh"
                 }
                 }
                 stage('Tomcat') {
                 steps {
                     echo 'create tomcat app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/tomcat/tomcat_startup.sh"
                 }
                 }
                 stage('SQLite') {
                 steps {
                     echo 'create SQlite app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/sqlite/sqlite_startup.sh"
                 }
                 }
         }
}