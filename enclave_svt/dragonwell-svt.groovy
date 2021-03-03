pipeline {
         agent {
             node {
                 label 'sgx-server'
                 customWorkspace '/home/data/jenkins'
             }
         }
         stages {
                 stage('Dragonwell Enclave Build') {
                 steps {
                     echo 'Download dragonwell resource code and build it'
                     sh "printenv"
                     sh "mkdir -p ${WORKSPACE}/workspace/${BUILD_TAG} && rm -rf ${WORKSPACE}/workspace/${BUILD_TAG}/*"
                     sh "wget -c ${dragonwell_repo_address} -O - | tar -xz -C ${WORKSPACE}/workspace/${BUILD_TAG} --strip-components 1"
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && \
                         mkdir tmp && git clone git@github.com:dragonwell-releng/dragonwell11-occlum-release.git ./tmp && \
                         mv ./tmp/* ./ && rm -rf tmp"
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./make_alpine.sh ${build_mode}"
                 }
                 }
                 stage('SpringBoot based on Occlum') {
                 steps {
                     echo 'Build SpringBoot and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/springboot/springboot_startup.sh"
                 }
                 }
                 stage('Java font support based on Occlum') {
                 steps {
                     echo 'create font app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/font/font_startup.sh"
                 }
                 }
                 stage('Java netty support based on Occlum') {
                 steps {
                     echo 'create netty app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/netty/netty_startup.sh"
                 }
                 }
         }
}