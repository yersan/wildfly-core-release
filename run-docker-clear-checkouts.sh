#!/bin/bash

CHECKOUTS_FOLDER=/home/wfcore/checkouts

docker run \
  --userns keep-id \
  --group-add keep-groups \
	-v  wfcore-release-checkouts:$CHECKOUTS_FOLDER \
	-it ${USER}/wildfly-core-release:11 \
	/home/wfcore/clean-volume.sh $CHECKOUTS_FOLDER
