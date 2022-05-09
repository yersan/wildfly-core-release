#!/bin/bash

CLEAN=$7

# In case of need a clean build, remove the following directories
if [ ! -z "${CLEAN}" ]; then
  echo "=================================================================================================="
  MAVEN_REPO=$(docker volume inspect --format '{{json .Mountpoint}}' wfcore-release-maven-repo)
  CHECKOUTS=$(docker volume inspect --format '{{json .Mountpoint}}' wfcore-release-checkouts)
  echo "Cleaning maven mount directories:"
  echo "Maven Repo=${MAVEN_REPO}"
  echo "Checkouts=${CHECKOUTS}"
  sudo rm -Rf "${MAVEN_REPO}"
  sudo rm -Rf "${CHECKOUTS}"
  echo "Done."
  echo "=================================================================================================="
fi

docker run \
  --memory=4G \
	-v ~/.m2/settings.xml:/home/wfcore/.m2/settings.xml \
	-v ~/.m2/settings-security.xml:/home/wfcore/.m2/settings-security.xml \
	-v wfcore-release-maven-repo-beta9:/home/wfcore/.m2 \
	-v wfcore-release-checkouts-beta9:/home/wfcore/checkouts \
	-v ~/.gitconfig:/home/wfcore/.gitconfig \
	-v ~/.ssh:/home/wfcore/.ssh \
	-it "${USER}/wildfly-core-release:11" \
	/home/wfcore/do-release.sh $1 $2 $3 $4 $5 $6