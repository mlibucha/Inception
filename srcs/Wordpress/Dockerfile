FROM php:8.2-fpm-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    zip \
    unzip \
    mariadb-client \
    libicu-dev \
    libonig-dev \
    gosu \
    bash \
   # sh -c 'echo -e "y"' \
    && rm -rf /var/lib/apt/lists/* 

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        intl \
        mbstring \
        zip \
        exif \
        pcntl \
        opcache

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html

COPY wp-fpm-entrypoint.sh /usr/local/bin/wp-fpm-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-fpm-entrypoint.sh

RUN { \
    echo "[global]"; \
    echo "daemonize = no"; \
    } > /usr/local/etc/php-fpm.conf \
    && { \
    echo "[www]"; \
    echo "user = www-data"; \
    echo "group = www-data"; \
    echo "listen = 0.0.0.0:9000"; \
    echo "listen.allowed_clients = 0.0.0.0/0"; \
    echo "pm = dynamic"; \
    echo "pm.max_children = 5"; \
    echo "pm.start_servers = 2"; \
    echo "pm.min_spare_servers = 1"; \
    echo "pm.max_spare_servers = 3"; \
    echo "clear_env = no"; \
    echo "php_admin_value[error_log] = /proc/self/fd/2"; \
    echo "php_admin_flag[log_errors] = on"; \
    } > /usr/local/etc/php-fpm.d/www.conf

RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm -t || exit 1

ENTRYPOINT ["/usr/local/bin/wp-fpm-entrypoint.sh"]

