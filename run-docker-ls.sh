#!/bin/bash

CHECKOUTS_FOLDER=/home/wfcore/checkouts

docker run \
  --userns keep-id \
  --group-add keep-groups \
	-v  wfcore-release-checkouts:$CHECKOUTS_FOLDER \
	-it wildfly-core-release \
	/home/wfcore/file-util.sh "ls" $1
