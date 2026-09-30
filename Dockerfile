FROM nginx:stable-alpine
LABEL org.opencontainers.image.title="Weevil City Cruisers" \
      org.opencontainers.image.description="Lightweight car club website with external year-based photo galleries" \
      org.opencontainers.image.source="https://github.com/avalanche208/weevilcitycruisers"
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY scripts/40-data-folders.sh /docker-entrypoint.d/40-data-folders.sh
RUN chmod +x /docker-entrypoint.d/40-data-folders.sh
EXPOSE 80
VOLUME /data
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
