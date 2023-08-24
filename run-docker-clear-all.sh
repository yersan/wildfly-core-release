#!/bin/bash

# Determine uid of host user for use a docker build argument
USER_ID=$(id -u)

docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)
docker volume rm wfcore-release-checkouts
docker volume rm wfcore-release-maven-repo
docker build -t ${USER}/wildfly-core-release:11 --build-arg USER_ID=${USER_ID} .
