#!/bin/sh
# renders /etc/dnsmasq.d/svamm.conf and adds the svamm host alias to /etc/hosts
set -eu

HOSTS=/etc/hosts

ALIAS="${SVAMM_HOST_ALIAS:-svamm.internal}"
case "$ALIAS" in
	'' | *[!A-Za-z0-9._-]*)
		echo "svamm-render-dns: invalid SVAMM_HOST_ALIAS '$ALIAS'" >&2
		exit 1
		;;
esac

# The msb-provisioned host alias already exists in /etc/hosts; derive the  gateway IPs (the sandbox host) from it.
GW_V4="$(awk '$2 == "host.microsandbox.internal" && $1 ~ /^[0-9]+(\.[0-9]+){3}$/ {print $1; exit}' "$HOSTS" 2>/dev/null || true)"
GW_V6="$(awk '$2 == "host.microsandbox.internal" && $1 ~ /:/ {print $1; exit}' "$HOSTS" 2>/dev/null || true)"

if [ -z "$GW_V4" ] && [ -z "$GW_V6" ]; then
	echo "svamm-render-dns: no host.microsandbox.internal entry in $HOSTS" >&2
	exit 1
fi

# Make the alias resolvable for guest processes (idempotent append, one line per address family).
for gw in "$GW_V4" "$GW_V6"; do
	[ -n "$gw" ] || continue
	if ! awk -v ip="$gw" -v a="$ALIAS" '$1 == ip && $2 == a { found = 1 } END { exit !found }' "$HOSTS"; then
		printf '%s\t%s\n' "$gw" "$ALIAS" >> "$HOSTS"
	fi
done

# Container DNS: answer the host aliases locally; everything else is
# forwarded to the upstream nameservers in /etc/resolv.conf as usual.
mkdir -p /etc/dnsmasq.d
{
	printf 'domain-needed\n'
	if [ -n "$GW_V4" ]; then
		printf 'address=/%s/%s\n' "$ALIAS" "$GW_V4"
		printf 'address=/host.microsandbox.internal/%s\n' "$GW_V4"
	fi
	if [ -n "$GW_V6" ]; then
		printf 'address=/%s/%s\n' "$ALIAS" "$GW_V6"
		printf 'address=/host.microsandbox.internal/%s\n' "$GW_V6"
	fi
} > /etc/dnsmasq.d/svamm.conf
