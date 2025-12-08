#!/bin/sh
set -e

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpass}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wordpress}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wordpress}

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory"
  mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

/usr/bin/mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &

for i in $(seq 1 30); do
  if mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
    break
  fi
  sleep 1
done


mysql --socket=/run/mysqld/mysqld.sock <<-EOSQL
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
  CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
  GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
  FLUSH PRIVILEGES;
EOSQL

mysqladmin --socket=/run/mysqld/mysqld.sock shutdown

exec /usr/bin/mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
