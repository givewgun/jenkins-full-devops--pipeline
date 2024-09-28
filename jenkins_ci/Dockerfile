FROM jenkins/jenkins:lts

# Install Jenkins plugins and their dependencies
RUN jenkins-plugin-cli --plugins \
    git \
    blueocean \
    sonar \
    workflow-job \
    workflow-aggregator \
    credentials-binding \
    docker-workflow \
    prometheus \
    ansible

# Skip initial setup
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Install Docker inside Jenkins container
USER root
RUN apt-get update && \
    apt-get install -y docker.io && \
    apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get install -y ansible && \
    apt-get clean

# Add Groovy script to create admin user and pipeline job
COPY init.groovy.d /usr/share/jenkins/ref/init.groovy.d/

# Override entrypoint to run both Docker service and Jenkins
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
