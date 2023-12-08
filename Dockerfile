FROM openjdk:11.0

ENV SCALA_VERSIONS='"2.12.12"' \
    SBT_VERSION=1.4.6 \
    DOCKER_VERSION=20.10.23 \
    FLYWAY_VERSION=9.8.1 \
    NODE_VERSION=18 \
    SERVERLESS_VERSION=3.36.0 \
    BUILD_PATH=/build

RUN mkdir -p ${BUILD_PATH}

WORKDIR /tmp

# install baseline system packages
RUN apt-get update \
    && apt-get install -y \
    bash ca-certificates curl git groff jq openssh-client openssl python sudo tar ncurses-base

# install node and serverless framework
RUN curl -sL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash - \
    && apt-get install -y nodejs \
    && sudo npm install -g "serverless@${SERVERLESS_VERSION}"

# install postgresdb
COPY bin/start_postgresdb.sh /usr/local/bin/

RUN apt-get install -y postgresql-13 \
    && mkdir -p /var/lib/postgresql/data \
    && chown postgres:postgres /var/lib/postgresql/data \
    && mkdir -p /run/postgresql \
    && chown postgres:postgres /run/postgresql/ \
    && sudo -u postgres /usr/lib/postgresql/13/bin/initdb /var/lib/postgresql/data \
    && echo "listen_addresses = 'localhost'" >> /etc/postgresql/13/main/postgresql.conf \
    && chmod +x /usr/local/bin/start_postgresdb.sh

# install flyway
RUN mkdir -p ${BUILD_PATH}/flyway \
    && cd ${BUILD_PATH}/flyway \
    && curl -Ls -o flyway.tar.gz "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz" \
    && tar -xzf flyway.tar.gz --strip-components=1 \
    && rm flyway.tar.gz \
    && ln -s ${BUILD_PATH}/flyway/flyway /usr/local/bin/flyway \
    && cd -

# install aws-cli
RUN curl -s -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install -i /usr/local/aws -b /usr/local/bin

# install redis
RUN apt-get install -y redis-server

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
