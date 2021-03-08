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
                 stage('SpringBoot') {
                 steps {
                     echo 'Build SpringBoot and make benchmark'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_benchmark/framework_benchmark/springboot/springboot_startup.sh"
                 }
                 }
                 stage('Netty') {
                 steps {
                     echo 'create netty app and make benchmark'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_benchmark/framework_benchmark/netty/netty_startup.sh"
                 }
                 }
                 stage('Tomcat') {
                 steps {
                     echo 'create tomcat app and make benchmark'
                     sh "cd ${WORKSPACE}/workspace/${BUILD_TAG} \
                         && ./enclave_benchmark/framework_benchmark/tomcat/tomcat_startup.sh"
                 }
                 }
                 stage('FrameWork BenchMark Report') {
                 steps {
                     echo 'Look up FrameWork BenchMark Report by HTML publisher'
                     sh "cp ${WORKSPACE}/workspace/${BUILD_TAG}/enclave_benchmark/framework_benchmark/report/. ${WORKSPACE}/workspace/Enclave_FWB_Report"
                     publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'workspace/Enclave_FWB_Report', reportFiles: '*.html', reportName: 'FrameWork Benchmark HTML Report', reportTitles: ''])
                 }
                 }
         }
}