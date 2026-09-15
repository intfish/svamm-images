# The svamm-managed local image registry: a single sandbox running both the
# registry (writable, host-only) and a read-only nginx proxy (the only
# endpoint sandboxes may reach). Sandbox pushes are refused with 405 so a
# process inside a sandbox cannot overwrite any image in the local registry.
#
# The registry binary is a static Go binary, copied verbatim from registry:2
# into an nginx base; no apk resolution is needed at build time.

FROM registry:2 AS regsrc
FROM nginx:alpine

COPY --from=regsrc /bin/registry /bin/registry
COPY --from=regsrc /etc/docker/registry/config.yml /etc/docker/registry/config.yml

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
