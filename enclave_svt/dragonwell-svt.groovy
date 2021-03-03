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
                     sh "mkdir -p ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && rm -rf ${WORKSPACE}/workspace/${BUILD_TAG}/*"
                     sh "wget -c ${dragonwell_repo_address} -O - | tar -xz -C ${WORKSPACE}/workspace/${BUILD_TAG} --strip-components 1"
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./make.sh ${build_mode}"
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
                 stage('Java svm support based on Occlum') {
                 steps {
                     echo 'wget svm app and run it based on Occlum'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_svt/svm/svm_startup.sh"
                 }
                 }
         }
}