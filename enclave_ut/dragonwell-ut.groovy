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
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./make_alpine.sh ${build_mode}"
                 }
                 }
                 stage('Unit Test') {
                 steps {
                     echo 'Make dragonwell jtreg ut for enclave'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./enclave_ut/dragonwell-ut.sh ${build_mode}"
                 }
                 }
                 stage('Unit Test On Occlum') {
                 steps {
                     echo 'Create Occlum enviroment and make ut in Occlum docker'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} && ./enclave_ut/dragonwell-enclave-ut.sh"
                 }
                 }
                 stage('Unit Test Report') {
                 steps {
                     echo 'Look up Enclave UT Report by HTML publisher'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG}/enclave_ut/ \
                         && ./dragonwell-enclave-ut-html.sh \
                         && cp ${WORKSPACE}/workspace/${BUILD_TAG}/enclave_ut/occlum_instance/*.html ${WORKSPACE}/workspace/Enclave_Report"
                     publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'workspace/Enclave_Report', reportFiles: 'enclave_ut_report.html', reportName: 'Enclave UT HTML Report', reportTitles: ''])
                 }
                 }
         }
}