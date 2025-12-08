#!/bin/sh
set -e

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpass}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wordpress}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wordpress}

if [ ! -d "/var/lib/mysql/mysql" ]; then
  mkdir -p /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
  echo "Running mariadbd --initialize..."
  mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
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

echo "Starting MariaDB server"
exec mysqld --user=mysql --datadir=/var/lib/mysql
