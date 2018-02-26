# Inspired by https://github.com/mumoshu/dcind
FROM alpine:3.7

LABEL maintainer.1="André Hähnel <andre.haehnel@netresearch.de>" \
      maintainer.2="Sebastian Mendel <sebastian.mendel@netresearch.de>"

ENV DOCKER_VERSION=17.05.0-ce \
    DOCKER_COMPOSE_VERSION=1.19.0 \
    ENTRYKIT_VERSION=0.4.0

# Install Docker and Docker Compose
RUN apk --update --no-cache add \
    bash \
    coreutils \
    curl \
    device-mapper \
    iptables \
    make \
    py-pip \
    redis \
 && apk upgrade \
 && curl https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx \
 && mv /docker/* /bin/ && chmod +x /bin/docker* \
 && pip install docker-compose==${DOCKER_COMPOSE_VERSION} \
 && pip install docker-squash \
# Install entrykit
 && curl -L https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz | tar zx \
 && chmod +x entrykit \
 && mv entrykit /bin/entrykit \
 && entrykit --symlink \
# cleanup
 && rm -rf /var/cache/apk/*


# Include useful functions to start/stop docker daemon in garden-runc containers in Concourse CI.
# Example: source /docker-lib.sh && start_docker
COPY docker-lib.sh /docker-lib.sh

ENTRYPOINT [ \
	"switch", \
		"shell=/bin/sh", "--", \
	"codep", \
		"/bin/dockerd" \
]
