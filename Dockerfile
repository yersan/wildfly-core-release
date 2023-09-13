# Base on the OpenJDK 11 image
FROM openjdk:11-jdk

RUN apt-get update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl

ARG MAVEN_HOST="dlcdn.apache.org"
ARG MAVEN_VERSION="3.9.4"
RUN	wget http://${MAVEN_HOST}/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -zxf apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    cp -R apache-maven-${MAVEN_VERSION} /usr/local && \
    ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn && \
    apt-get install git;\
    \
	apt-get purge -y --auto-remove $fetchDeps

ARG USER_ID
# Require USER_ID build argument
RUN test -n "${USER_ID}"
# Create wfcore user, using same uid as host user
RUN useradd --shell /bin/bash -u ${USER_ID} -o -c "" -m wfcore

#Add the script that will do the work
ADD container/clean-volume.sh /home/wfcore/clean-volume.sh
ADD container/do-release.sh /home/wfcore/do-release.sh
ADD container/file-util.sh /home/wfcore/file-util.sh

