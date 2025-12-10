FROM php:8.2-fpm-alpine3.19

RUN apk add --no-cache \
        bash \
        curl \
        git \
        freetype \
        icu-libs \
        libjpeg-turbo \
        libpng \
        libwebp \
        libzip \
        mariadb-client \
        oniguruma \
        su-exec \
        unzip \
        zip

RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        autoconf \
        build-base \
        freetype-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        oniguruma-dev \
        pkgconf; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        intl \
        mbstring \
        zip \
        exif \
        pcntl \
        opcache; \
    apk del .build-deps

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html

RUN echo "memory_limit = 512M" > /usr/local/etc/php/conf.d/zzz-memory-limit.ini

COPY wp-fpm-entrypoint.sh /usr/local/bin/wp-fpm-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-fpm-entrypoint.sh

RUN { \
    echo "[global]"; \
    echo "daemonize = no"; \
    echo "include = /usr/local/etc/php-fpm.d/*.conf"; \
    } > /usr/local/etc/php-fpm.conf \
    && { \
    echo "[www]"; \
    echo "user = www-data"; \
    echo "group = www-data"; \
    echo "listen = 0.0.0.0:9000"; \
    echo "pm = dynamic"; \
    echo "pm.max_children = 5"; \
    echo "pm.start_servers = 2"; \
    echo "pm.min_spare_servers = 1"; \
    echo "pm.max_spare_servers = 3"; \
    echo "clear_env = no"; \
    echo "php_admin_value[error_log] = /proc/self/fd/2"; \
    echo "php_admin_flag[log_errors] = on"; \
    echo "php_admin_value[memory_limit] = 512M"; \
    } > /usr/local/etc/php-fpm.d/www.conf

RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm -t || exit 1

ENTRYPOINT ["/usr/local/bin/wp-fpm-entrypoint.sh"]
CMD ["php-fpm", "-F"]

