#!/bin/sh
# Runs the registry and the read-only nginx proxy in one container.
# The container is the msb handoff init (PID 1) for the registry sandbox;
# it must stay alive while either service is up and must exit on TERM/INT so
# `msb stop` / `svamm stop` can tear the sandbox down.
set -e

CONFIG="${1:-/etc/docker/registry/config.yml}"

/bin/registry serve "$CONFIG" &
REG_PID=$!

nginx -g 'daemon off;' &
NGINX_PID=$!

shutdown() {
	kill -TERM "$REG_PID" "$NGINX_PID" 2>/dev/null || true
	wait || true
	exit 0
}
trap shutdown TERM INT

# If either service dies, exit so svamm can recreate the sandbox.
while kill -0 "$REG_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do
	sleep 1
done

kill -TERM "$REG_PID" "$NGINX_PID" 2>/dev/null || true
wait || true
exit 1
