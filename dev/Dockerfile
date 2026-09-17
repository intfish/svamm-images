# building:
# docker build -t 127.0.0.1:<registry_port>/dev:<tag> dev
# docker push 127.0.0.1:<registry_port>/dev:<tag>
#
# ~/.config/svamm/config.toml:
# images.vm = "127.0.0.1:<registry_port>/dev:<tag>"

ARG SVAMM_BASE_IMAGE=ghcr.io/intfish/svamm-images/svamm:latest
FROM ${SVAMM_BASE_IMAGE}

USER root

# build toolchain
RUN apt-get update && \
	apt-get install -y \
		build-essential \
		btop \
		clang \
		cmake \
		gnupg \
		htop \
		libcap-ng-dev \
		libpq5 \
		libpq-dev \
		libssl-dev \
		postgresql-client \
		python3-dev \
		python3-pip \
	&& rm -rf /var/lib/apt/lists/*

USER agent

# rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/agent/.cargo/bin:${PATH}"
RUN rustup component add rustfmt clippy
RUN which rust-analyzer

# tools from nix
RUN nix --extra-experimental-features 'nix-command flakes' profile add \
	nixpkgs#zig \
	nixpkgs#lua nixpkgs#lua-language-server

WORKDIR /home/agent
