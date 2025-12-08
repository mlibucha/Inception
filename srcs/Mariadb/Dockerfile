FROM mariadb:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server mariadb-client ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY mariadb-entrypoint.sh /mariadb-entrypoint.sh
RUN chmod +x /mariadb-entrypoint.sh

EXPOSE 3306
CMD ["/mariadb-entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD mysqladmin ping -h localhost -u root --password=$$MYSQL_ROOT_PASSWORD || exit 1