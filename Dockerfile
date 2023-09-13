# Base on the OpenJDK 11 image
FROM openjdk:11-jdk

RUN apt-get update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl

RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

ARG MAVEN_HOST="dlcdn.apache.org"
ARG MAVEN_VERSION="3.9.4"
RUN	wget http://${MAVEN_HOST}/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -zxf apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    cp -R apache-maven-${MAVEN_VERSION} /usr/local && \
    ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn && \
    apt-get install git;\
    \
	apt-get purge -y --auto-remove $fetchDeps

#Add the script that will do the work
ADD container/clean-volume.sh /home/wfcore/clean-volume.sh
ADD container/do-release.sh /home/wfcore/do-release.sh
ADD container/file-util.sh /home/wfcore/file-util.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
