#!/bin/bash

docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)
docker volume rm wfcore-release-checkouts
docker volume rm wfcore-release-maven-repo
docker build -t ${USER}/wildfly-core-release:11 .
