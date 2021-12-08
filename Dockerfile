FROM docker:dind as upstream

ENV DOCKER_COMPOSE_VERSION=2.2.2 \
    ENTRYKIT_VERSION=0.4.0

# Install Docker and Docker Compose
RUN apk update
RUN apk upgrade
RUN apk add \
    bash \
    coreutils \
    curl \
    device-mapper \
    iptables \
    make \
    redis
RUN mkdir -p /usr/local/lib/docker/cli-plugins
RUN curl -o /usr/local/lib/docker/cli-plugins/docker-compose -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64
RUN chmod ugo+x /usr/local/lib/docker/cli-plugins/docker-compose
RUN ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/
RUN docker compose version
RUN docker-compose version
# Install entrykit
RUN curl -L https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz | tar zx
RUN chmod +x entrykit
RUN mv entrykit /usr/local/bin/entrykit
RUN entrykit --symlink
# cleanup
RUN rm -rf /var/cache/apk/*
RUN rm -rf /root/.cache

# copy everything to a clean image, so we can change the exposed ports
# this is required to fix GitLab CI/CD - which is waitng for all exposed ports
FROM scratch

LABEL maintainer.1="André Hähnel <andre.haehnel@netresearch.de>" \
      maintainer.2="Sebastian Mendel <sebastian.mendel@netresearch.de>"

COPY --from=upstream / /

# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh

COPY setup /

VOLUME /var/lib/docker

# EXPOSE 2376 # is for TLS connections, and having both breaks gitlab "wait-for-it" service
EXPOSE 2375

ENTRYPOINT [ "switch", "shell=/bin/bash", "--", "codep", "/usr/local/bin/dockerd" ]
