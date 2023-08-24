#!/bin/bash

docker run \
  --memory=4G \
  --userns keep-id \
  --group-add keep-groups \
	-v ~/.m2/settings.xml:/home/wfcore/.m2/settings.xml \
	-v wfcore-release-maven-repo:/home/wfcore/.m2 \
	-v wfcore-release-checkouts:/home/wfcore/checkouts \
	-v ~/.gitconfig:/home/wfcore/.gitconfig \
	-v ~/.ssh:/home/wfcore/.ssh \
 	-v ~/.gnupg:/home/wfcore/.gnupg \
	-it ${USER}/wildfly-core-release:11 \
  bash
