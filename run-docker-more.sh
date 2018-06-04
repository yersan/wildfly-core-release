#!/bin/bash

CHECKOUTS_FOLDER=/home/wfcore/checkouts

docker run \
	-v  wfcore-release-checkouts:$CHECKOUTS_FOLDER \
	-it wildfly-core-release \
	/home/wfcore/file-util.sh "more" $1
