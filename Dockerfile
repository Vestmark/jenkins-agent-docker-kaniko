FROM gcr.io/kaniko-project/executor:debug as kaniko

FROM busybox:1.31.1 as busybox

FROM jenkins/inbound-agent:latest-alpine-jdk11

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
RUN curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' \
      -o 'awscliv2.zip' && \
      unzip awscliv2.zip && \
      ./aws/install

COPY --from=kaniko /kaniko /kaniko
COPY --from=busybox /bin /busybox

ENV PATH=/busybox:/kaniko:$PATH

WORKDIR /opt/java

#RUN mkdir -p /usr/lib/jvm

#RUN wget https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz

#RUN tar -xzf OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz

#RUN ln -s /opt/java/openjdk-8u275-b01 /usr/lib/jvm/jdkredhat-openjdk-1.8.0.275

#RUN rm -f OpenJDK8U-jdk_x64_linux_8u275b01.tar.gz

#RUN wget https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.16%2B8/OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz

#RUN tar -xzf OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz

#RUN ln -s /opt/java/openjdk-11.0.16_8 /usr/lib/jvm/openjdk-11.0.16_8

#RUN sed 's+$JAVA_BIN $JAVA_OPTIONS+/opt/java/openjdk-native-install/bin/java $JAVA_OPTIONS+g' /usr/local/bin/jenkins-agent > /usr/local/bin/jenkins-agent-java11

#RUN chmod +x /usr/local/bin/jenkins-agent-java11

#RUN mv /opt/java/openjdk /opt/java/openjdk-native-install

#RUN ln -s /usr/lib/jvm/jdkredhat-openjdk-1.8.0.275 /opt/java/openjdk

#RUN rm -f OpenJDK11U-jdk_x64_linux_11.0.16_8.tar.gz
# Docker volumes include an entry in /proc/self/mountinfo. This file is used
# when kaniko builds the list of whitelisted directories. Whitelisted
# directories are persisted between stages and are not included in the final
# Docker image.
VOLUME /busybox

# The /kaniko directory is whitelisted by default. Its contents are not de-
# leted between stages, nor is it included in the final Docker image.
WORKDIR /kaniko
