FROM nginx:stable-alpine
LABEL org.opencontainers.image.title="Weevil City Cruisers" \
      org.opencontainers.image.description="Lightweight car club website with external year-based photo galleries" \
      org.opencontainers.image.source="https://github.com/avalanche208/weevilcitycruisers"
RUN apk add --no-cache python3 vips-tools vips-heif fcgiwrap spawn-fcgi
COPY scripts/thumbnail-server.py /opt/wcc/thumbnail-server.py
COPY scripts/45-thumbnail-server.sh /docker-entrypoint.d/45-thumbnail-server.sh
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY scripts/40-data-folders.sh /docker-entrypoint.d/40-data-folders.sh
RUN chmod +x /opt/wcc/thumbnail-server.py /docker-entrypoint.d/40-data-folders.sh /docker-entrypoint.d/45-thumbnail-server.sh \
    && sed -i 's/^worker_processes .*/worker_processes 1;/' /etc/nginx/nginx.conf
EXPOSE 80
VOLUME /data
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
