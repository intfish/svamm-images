#!/bin/sh
# renders /etc/docker/daemon.json before the docker daemon starts
set -eu

PORT="${SVAMM_REGISTRY_PROXY_PORT:-}"
if [ -z "$PORT" ]; then
	PORT="$(tr '\0' '\n' < /proc/1/environ 2>/dev/null \
		| sed -n 's/^SVAMM_REGISTRY_PROXY_PORT=//p' \
		| head -n 1 || true)"
fi
PORT="${PORT:-50001}"

mkdir -p /etc/docker
printf '{"insecure-registries":["host.microsandbox.internal:%s"]}\n' "$PORT" > /etc/docker/daemon.json
