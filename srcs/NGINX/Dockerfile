

FROM nginx:alpine



RUN apk add --no-cache \
    curl \
    bash \
    certbot \
    certbot-nginx

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf



COPY ssl/ /etc/nginx/ssl/
COPY nginex-entrypoint.sh /nginx-entrypoint.sh
RUN chmod +x /nginx-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

ENTRYPOINT [ "/nginx-entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
