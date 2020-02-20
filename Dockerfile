FROM openjdk:8-jdk-alpine

ENV SCALA_VERSIONS='"2.11.12", "2.12.8"' \
    SBT_VERSION=1.2.6 \
    DOCKER_VERSION=18.09.9 \
    AWS_CLI_VERSION=1.17.9 \
    BUILD_PATH=/build

RUN mkdir -p ${BUILD_PATH}

WORKDIR /tmp

RUN apk add --no-cache --update \
    bash ca-certificates curl git openssh openssl python tar ncurses

RUN curl -s -o awscli-bundle.zip "https://s3.amazonaws.com/aws-cli/awscli-bundle-${AWS_CLI_VERSION}.zip" \
    && unzip awscli-bundle.zip \
    && chmod +x ./awscli-bundle/install \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

RUN curl -Ls -o sbt.tar.gz "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
    && tar -vxzf sbt.tar.gz \
    && chmod 755 sbt/bin/sbt \
    && chown root:root sbt \
    && mv sbt ${BUILD_PATH}/ \
    && ln -s ${BUILD_PATH}/sbt/bin/sbt /usr/bin \
    && mkdir -p ~/.sbt/1.0/plugins/

RUN curl -s -o docker.tar.gz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    && tar -xzvf docker.tar.gz \
    && mv /tmp/docker/* /usr/bin/

RUN rm -rf /tmp/*

WORKDIR ${BUILD_PATH}

RUN echo "crossScalaVersions := Seq(${SCALA_VERSIONS})" > build.sbt \
    && echo 'object Hi { def main(args: Array[String]) = println("Done") }' > src.scala \
    && sbt "+run" \
    && rm build.sbt src.scala
