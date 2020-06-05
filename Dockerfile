FROM openjdk:8-jdk-alpine

ENV SCALA_VERSIONS='"2.11.12", "2.12.8", "2.12.10", "2.13.2"' \
    SBT_VERSION=1.3.12 \
    DOCKER_VERSION=18.09.9 \
    AWS_CLI_VERSION=1.17.9 \
    FLYWAY_VERSION=6.3.3 \
    SERVERLESS_VERSION=1.67.3 \
    BUILD_PATH=/build

RUN mkdir -p ${BUILD_PATH}

WORKDIR /tmp

# install baseline system packages
RUN apk add --no-cache --update \
    bash ca-certificates curl git jq openssh openssl python sudo tar ncurses

# install serverless framework
RUN apk add --no-cache --update nodejs npm \
    && npm install -g serverless@${SERVERLESS_VERSION}

# install postgresdb
COPY bin/start_postgresdb.sh /usr/local/bin/

RUN apk add --no-cache --update postgresql \
    && mkdir -p /var/lib/postgresql/data \
    && chown postgres:postgres /var/lib/postgresql/data \
    && mkdir -p /run/postgresql \
    && chown postgres:postgres /run/postgresql/ \
    && sudo -u postgres initdb /var/lib/postgresql/data \
    && echo "listen_addresses = 'localhost'" >> /var/lib/postgresql/data/postgresql.conf \
    && chmod +x /usr/local/bin/start_postgresdb.sh

# install flyway
RUN mkdir -p ${BUILD_PATH}/flyway \
    && cd ${BUILD_PATH}/flyway \
    && curl -Ls -o flyway.tar.gz https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz \
    && tar -xzf flyway.tar.gz --strip-components=1 \
    && rm flyway.tar.gz \
    && ln -s ${BUILD_PATH}/flyway/flyway /usr/local/bin/flyway \
    && cd -

RUN curl -s -o awscli-bundle.zip "https://s3.amazonaws.com/aws-cli/awscli-bundle-${AWS_CLI_VERSION}.zip" \
    && unzip awscli-bundle.zip \
    && chmod +x ./awscli-bundle/install \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# install sbt
RUN curl -Ls -o sbt.tar.gz "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
    && tar -vxzf sbt.tar.gz \
    && chmod 755 sbt/bin/sbt \
    && chown root:root sbt \
    && mv sbt ${BUILD_PATH}/ \
    && ln -s ${BUILD_PATH}/sbt/bin/sbt /usr/bin \
    && mkdir -p ~/.sbt/1.0/plugins/

# install docker
RUN curl -s -o docker.tar.gz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    && tar -xzvf docker.tar.gz \
    && mv /tmp/docker/* /usr/bin/

RUN rm -rf /tmp/*

WORKDIR ${BUILD_PATH}

# run test compile to force sbt to download specified scala versions
RUN echo "crossScalaVersions := Seq(${SCALA_VERSIONS})" > build.sbt \
    && echo 'object Hi { def main(args: Array[String]) = println("Done") }' > src.scala \
    && sbt "+run" \
    && rm build.sbt src.scala
