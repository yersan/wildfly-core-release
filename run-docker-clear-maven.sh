#!/bin/bash

LOCAL_MAVEN_TREE=/home/wfcore/.m2/repository/org/wildfly

docker run \
	-v ~/.m2:/home/wfcore/.m2 \
	-v wfcore-release-maven-repo:$LOCAL_MAVEN_TREE \
	-it wildfly-core-build-temp \
	/home/wfcore/clean-volume.sh $LOCAL_MAVEN_TREE
