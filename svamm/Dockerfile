FROM debian:trixie-slim

USER root

RUN apt-get update && \
	apt-get install -y \
		bash \
		ca-certificates \
		curl \
		dnsmasq \
		git \
		lld \
		locales \
		nano \
		netcat-openbsd \
		net-tools \
		pkg-config \
		ripgrep \
		shellcheck \
		sqlite3 \
		systemd \
		systemd-sysv \
		xz-utils \
		zsh \
	&& rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.UTF-8

# docker
RUN install -m 0755 -d /etc/apt/keyrings && \
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
	chmod a+r /etc/apt/keyrings/docker.asc && \
	tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
RUN apt-get update && \
	apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
	rm -rf /var/lib/apt/lists/*

RUN systemctl enable docker

# the svamm-managed local image registry is plain HTTP and is reached inside sandboxes through
# the msb-provided host alias host.microsandbox.internal:<port>;
COPY render-daemon.sh /usr/local/bin/svamm-render-daemon.sh
COPY svamm-daemon.service /etc/systemd/system/svamm-daemon.service
RUN chmod +x /usr/local/bin/svamm-render-daemon.sh && \
	systemctl enable svamm-daemon.service

# guest-side dns resolver
COPY render-dns.sh /usr/local/bin/svamm-render-dns.sh
COPY svamm-dns.service /etc/systemd/system/svamm-dns.service
RUN chmod +x /usr/local/bin/svamm-render-dns.sh && \
	systemctl enable svamm-dns.service && \
	systemctl mask dnsmasq.service

RUN groupadd -g 1000 agent
RUN useradd -m -d /home/agent -s /usr/bin/zsh -u 1000 -g 1000 -G docker agent
RUN mkdir -m 0755 /nix && chown agent:agent /nix

USER agent

# nix
RUN set -o pipefail && curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon
ENV PATH="/home/agent/.nix-profile/bin:${PATH}"

# tools from nix
RUN nix --extra-experimental-features 'nix-command flakes' profile add \
	nixpkgs#fd \
	nixpkgs#nodejs

# tools from nodejs
RUN mkdir -p /home/agent/.local/bin
ENV PATH="/home/agent/.local/bin:${PATH}"
RUN npm config set prefix '~/.local/' && \
	npm i -g pnpm opencode-ai

# creature comforts
RUN mkdir -p /home/agent/.config/opencode/themes && \
	mkdir -p /home/agent/.local/state/opencode && \
	echo '{"theme":"svamm"}' > /home/agent/.local/state/opencode/kv.json
COPY svamm.json /home/agent/.config/opencode/themes/svamm.json
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cat <<EOT > "$HOME/.zshrc"
export ZSH="\$HOME/.oh-my-zsh"
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
ZSH_THEME="gnzh"
DISABLE_AUTO_UPDATE=true
plugins=(git docker docker-compose)
source "\$ZSH/oh-my-zsh.sh"
zstyle ':omz:update' mode disabled
EOT

WORKDIR /home/agent
