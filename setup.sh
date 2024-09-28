#!/bin/bash

# Step 1: Start Jenkins and SonarQube containers
docker-compose up -d --build

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 100

# Jenkins configuration
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASS="admin"

#Generate Jenkins Token
JENKINS_CRUMB=$(curl -u "$JENKINS_USER:$JENKINS_PASS" -s --cookie-jar /tmp/cookies $JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo "got Jenkins CRUMB..."

ACCESS_TOKEN=$(curl -u "$JENKINS_USER:$JENKINS_PASS" -H $JENKINS_CRUMB -s \
                    --cookie /tmp/cookies $JENKINS_URL'/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken' \
                    --data 'newTokenName=GlobalToken' | jq -r '.data.tokenValue')
echo "got Jenkins TOKEN..."

# SonarQube configuration
SONARQUBE_URL="http://localhost:9000"
SONARQUBE_USER="admin"
SONARQUBE_PASS="admin"
uuid=$(uuidgen)
PROJECT_NAME="jenkins-token-$uuid"

# Check if SonarQube token exists, if not create a new one
SONARQUBE_TOKEN=$(curl --silent -u ${SONARQUBE_USER}:${SONARQUBE_PASS} -X POST "${SONARQUBE_URL}/api/user_tokens/generate" -d name="${PROJECT_NAME}" | jq --raw-output '.token')
echo "New SonarQube token created: $SONARQUBE_TOKEN"

# Adding Sonarqube token to Jenkins
curl -u $JENKINS_USER:$ACCESS_TOKEN \
    -H $JENKINS_CRUMB \
    -H 'content-type:application/xml' \
    "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
    -d "<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
          <scope>GLOBAL</scope>
          <id>Sonar-token</id>
          <description>SonarQube token</description>
          <secret>${SONARQUBE_TOKEN}</secret>
        </org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>"
echo "Sonarqube Token added to Jenkins..."


# Permanently set Sonarqube Password to admin for easier access
curl -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=admin2"
curl -u admin:admin2 -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin2&password=admin"
echo "Changed Sonarqube admin password..."