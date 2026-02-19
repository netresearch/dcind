FROM docker:dind AS upstream

ENV ENTRYKIT_VERSION=0.4.0

# Install system packages
RUN apk update && apk upgrade && apk add --no-cache \
    bash \
    coreutils \
    curl \
    device-mapper \
    iptables \
    make \
    redis

# Ensure docker-compose CLI compatibility symlink exists (docker:dind ships with compose plugin)
RUN ln -sf /usr/local/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose \
    && docker compose version \
    && docker-compose version

# Install entrykit
RUN curl -L https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz | tar zx \
    && chmod +x entrykit \
    && mv entrykit /usr/local/bin/entrykit \
    && entrykit --symlink

# cleanup
RUN rm -rf /var/cache/apk/* /root/.cache

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
