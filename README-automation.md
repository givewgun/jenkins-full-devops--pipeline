# Step to run automation script

1. Copy the content of the SSH private key (`.pem` file) of your Amazon EC2 instance that you want to deploy and paste it in the `./jenkins_ci/init.groovy.d/ec2.pem` file in this project.
    - This is for Jenkins to set it as a credential to be used later in deployment.
    - Credential settings are in the `./jenkins_ci/init.groovy.d/init.groovy` script, lines 53-65.
2. (Optional) Change the repository or the branch that is the target of the pipeline in `./jenkins_ci/init.groovy.d/init.groovy` (lines 40-41).
3. Add execution permission to the script by running `chmod +x setup.sh`.
4. Run the `setup.sh` script using this command: `./setup.sh`
    - What it does:
        - It will build the Jenkins Docker image and start the whole stack by running `docker-compose up -d`.
        - It will set up the necessary Jenkins API token for usage later in the script.
        - It will call the SonarQube `/api/user_tokens/generate` API to generate a token to be used in Jenkins.
        - It will call the Jenkins `/credentials/store/system/domain/_/createCredentials` API to store the SonarQube token we obtained in the last step as a secret text to be used in the pipeline defined in the Jenkinsfile in the spring-petclinic repo.
5. Wait, and the stack and pipeline should be automatically created and triggered.
6. See the result of the pipeline trigger in the Jenkins URL (`localhost:8080`).