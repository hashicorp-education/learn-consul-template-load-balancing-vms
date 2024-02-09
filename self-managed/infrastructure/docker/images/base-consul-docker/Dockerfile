# ARG CONSUL_VERSION
# ARG ENVOY_VERSION
ARG BASE_IMAGE

# ----------------- #
# | DOCKER IMAGES | #
# ----------------- #

# FROM hashicorp/consul:${CONSUL_VERSION} as consul-bin
# FROM envoyproxy/envoy:${ENVOY_VERSION} as envoy-bin
# FROM grafana/agent:latest as grafana-agent-bin
# FROM hashicorp/consul-template:latest as consul-template-bin

FROM ${BASE_IMAGE}

# ----------------- #
# | SW PACKAGES   | #
# ----------------- #

RUN apt update \
    && apt install -y ca-certificates openssh-client \
    wget curl iptables supervisor procps \
    && rm -rf /var/lib/apt/list/*

ENV DOCKER_CHANNEL=stable \
	DOCKER_VERSION=24.0.6 \
	DOCKER_COMPOSE_VERSION=v2.22.0 \
	DEBUG=false \
    dockerArch='aarch64'

# Docker installation
RUN set -eux; \
	\
	# arch="$(uname --m)"; \
	# case "$arch" in \
    #     # amd64
	# 	x86_64) dockerArch='x86_64' ;; \
    #     # arm32v6
	# 	armhf) dockerArch='armel' ;; \
    #     # arm32v7
	# 	armv7) dockerArch='armhf' ;; \
    #     # arm64v8
	# 	aarch64|arm64) dockerArch='aarch64' ;; \
	# 	*) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;;\
	# esac; \
	# \
	if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	docker --version

COPY modprobe startup.sh /usr/local/bin/
COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/modprobe
VOLUME /var/lib/docker

# https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-linux-aarch64

# Docker compose installation
RUN curl --silent -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${dockerArch}" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose && docker-compose version


# ----------------- #
# | ENTRYPOINT    | #
# ----------------- #

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

CMD ["startup.sh"]