#!/bin/bash

LOCAL_MAVEN_TREE=/home/wfcore/.m2/repository/org/wildfly

docker run \
  --userns keep-id \
  --group-add keep-groups \
	-v ~/.m2:/home/wfcore/.m2 \
	-v wfcore-release-maven-repo:$LOCAL_MAVEN_TREE \
	-it wildfly-core-release \
	/home/wfcore/clean-volume.sh $LOCAL_MAVEN_TREE
