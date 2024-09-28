#!/bin/bash

# Start Docker service
service docker start

# Start Jenkins
exec /usr/local/bin/jenkins.sh "$@"
