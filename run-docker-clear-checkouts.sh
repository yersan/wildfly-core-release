#!/bin/bash

CHECKOUTS_FOLDER=/home/wfcore/checkouts

docker run \
	-v  wfcore-release-checkouts:$CHECKOUTS_FOLDER \
	-it wildfly-core-build-temp \
	/home/wfcore/clean-volume.sh $CHECKOUTS_FOLDER
