

FROM nginx:alpine



RUN apk add --no-cache \
    curl \
    bash \
    openssl \
    certbot \
    certbot-nginx

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf



RUN mkdir -p /etc/nginx/ssl
COPY ssl/ /etc/nginx/ssl/
RUN if [ ! -s /etc/nginx/ssl/server.crt ] || [ ! -s /etc/nginx/ssl/server.key ]; then \
            echo "Generating default self-signed certificate"; \
            openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 365 \
                -keyout /etc/nginx/ssl/server.key \
                -out /etc/nginx/ssl/server.crt \
                -subj "/CN=localhost"; \
        fi
COPY nginex-entrypoint.sh /nginx-entrypoint.sh
RUN chmod +x /nginx-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

ENTRYPOINT [ "/nginx-entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
