FROM gcr.io/kaniko-project/executor:v1.6.0 as kaniko

FROM busybox:1.31.1 as busybox

FROM jenkins/inbound-agent:4.7-1-alpine

# By default, the JNLP3-connect protocol is disabled due to known stability
# and scalability issues. You can enable this protocol using the
# JNLP_PROTOCOL_OPTS environment variable:
#
# JNLP_PROTOCOL_OPTS=-Dorg.jenkinsci.remoting.engine.JnlpProtocol3.disabled=false
#
# The JNLP3-connect protocol should be enabled on the Master instance as well.

ENV JNLP_PROTOCOL_OPTS=-Dorg.jenkinsci.remoting.engine.JnlpProtocol3.disabled=false

# Disable the JVM PerfDataFile feature by adding `-XX:-UsePerfData` to the
# `JAVA_OPTS` environment variable. Otherwise, a superfluous
# `/tmp/hsperfdata_root` directory will be included in the final Docker image.

ENV JAVA_OPTS -XX:-UsePerfData

# apk and kaniko must be run as root.
USER root

# Install minimally required packages
RUN apk add --no-cache --update \
      build-base \
      make

# Install additional packages
RUN apk add --update --no-cache \
      wget \
      curl \
      coreutils \
      python3

# Install the AWS CLI using the bundled installer
RUN curl 'https://s3.amazonaws.com/aws-cli/awscli-bundle.zip' \
      -o 'awscli-bundle.zip' && \
      unzip awscli-bundle.zip && \
      python3 ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

COPY --from=kaniko /kaniko /kaniko
COPY --from=busybox /bin /busybox

ENV PATH=/busybox:/kaniko:$PATH

WORKDIR /opt/java

RUN mkdir -p /usr/lib/jvm

RUN wget https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.16%2B8/OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz

RUN tar -xzf OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz

RUN ln -s /opt/java/openjdk-11.0.16_8 /usr/lib/jvm/openjdk-11.0.16_8

RUN rm -f OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz
# Docker volumes include an entry in /proc/self/mountinfo. This file is used
# when kaniko builds the list of whitelisted directories. Whitelisted
# directories are persisted between stages and are not included in the final
# Docker image.
VOLUME /busybox

# The /kaniko directory is whitelisted by default. Its contents are not de-
# leted between stages, nor is it included in the final Docker image.
WORKDIR /kaniko
