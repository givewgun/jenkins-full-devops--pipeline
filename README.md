# final-project-devops-group3

## Contributors - Group #3
- Dan Hales
- Gun Kaewngarm
- Muhammad Adinandra
- Minh Khue Le

## Demo Videos (YouTube)
- Functional Pipeline - https://www.youtube.com/watch?v=4TT26wyyGA0
- Automation - https://www.youtube.com/watch?v=e2fhH0ZWcXY

## Step-by-Step instructions:
For Step-by-step instructions on setting up each service, as well as screenshots of how they are set up, check out specific READMEs as following:
- [README-Jenkins](README-jenkins.md)
- [README-SonarQube](README-sonarqube.md)
- [README-Prometheus](README-prometheus.md)
- [README-Grafana](README-grafana.md)
- [README-Ansible](README-ansible.md)
- [README-OWASP](README-OWASP.md)
- [Artifacts (Petclinic-Repo)](artifacts/README.md)


## General Docker Compose setup:
We use docker compose to set up Jenkins, SonarQube, Prometheus and Grafana service containers.
Before running the steps below, get Docker and Docker Compose installed.
1. Run the following command to start all services:
```
docker compose up -d
```
1. Access each services UI:
Jenkins: http://localhost:8080.
SonarQube: http://localhost:9000.
Prometheus: http://localhost:9090.
Grafana: http://localhost:3000. For the dashboard: checkout http://localhost:3000/d/jenkins/jenkins3a-performance-and-health-overview?orgId=1
1. To remove the services, run: `docker compose down`



## Jenkinsfile:
The pipeline is described with a jenkinsfile on the application repo as following:
```
pipeline {
    agent any 

    stages {
        stage('Clean') {
            steps {
                script {
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
            }
        }

        stage('Build') {
            steps {
                sh './mvnw clean package -DskipTests'
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
```
### Stages
We can see from the Jenkinsfile that our pipeline would have these following stages:
1. Clean: Removes generated files from previous usage.
2. Build: Set up pet clinic app
3. SonarQube Analysis: performs SonarQube analysis on the application.
4. Run OWASP ZAP: Runs the OWASP ZAP tool for security testing. 
5. Deploy to EC2: Deploys the application to an EC2 instance using Ansible.
