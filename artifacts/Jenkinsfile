pipeline {
    agent any 

    stages {
        stage('Clean') {
            try {
                sh 'rm testreport.html'
            } catch (Exception e) {
                echo 'no test here'
            }
            try {
                sh 'rm zap.yaml'
            } catch (Exception e) {
                echo 'no yml here'
            }

        }

        stage('Build') {
            steps {
                sh './mvnw clean package'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SNQ_IP = "sonarqube"
                PROJECT_NAME = "Spring-Petclinic"
            }
            steps {
                withCredentials([string(credentialsId: 'Sonar-token', variable: 'SNQ_TOKEN')]) {
                    sh './mvnw sonar:sonar -Dsonar.projectKey=${PROJECT_NAME} -Dsonar.host.url=http://${SNQ_IP}:9000 -Dsonar.login=${SNQ_TOKEN}'
                }
                echo "(Please use this) Host SonarQube Dashboard URL: http://localhost:9000/dashboard?id=${env.PROJECT_NAME}"
            }
        }
        
        stage('Run OWASP ZAP') {
            steps {
                script {
                    try {
                        sh 'java -jar target/*.jar & echo $! > java_pid.txt &'
    
                        sleep 30
                        
                        // Pull the OWASP ZAP Docker image
                        sh 'docker pull zaproxy/zap-stable'

                        try {
                        // Run OWASP ZAP Docker container
                        sh 'docker run --privileged -v $(pwd):/zap/wrk/:rw -t --name owasp-zap zaproxy/zap-stable zap-baseline.py -t http://$(hostname -i):3000 -r testreport.html'
                            
                        } catch (Exception e) {
                            echo 'Ignore error during ZAP script.'
                            sh 'pwd'
                            sh 'ls'
                        }

                        sh 'docker cp owasp-zap:/zap/wrk/testreport.html ${WORKSPACE}/testreport.html'
                        
                    } finally {
                        
                        // Kill the Java process
                        sh 'kill $(cat java_pid.txt) || true'

                        // Clean up containers
                        sh 'docker stop owasp-zap || true'
                        sh 'docker rm owasp-zap || true'
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                ansiblePlaybook(
                    playbook: 'deploy.yml',
                    inventory: 'inventory',
                    credentialsId: 'ec2-key'
                )
            }
        }
    }

    post {
        always {
            script {
                // Publish the HTML report
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '',
                    reportFiles: 'testreport.html',
                    reportName: 'OWASP ZAP Report',
                    reportTitles: 'OWASP ZAP Security Test Report'
                ])
            }
        }
    }
}