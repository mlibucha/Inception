#!/bin/sh
set -e

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpass}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wordpress}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wordpress}

MARIADB_DAEMON=$(command -v mariadbd || command -v mysqld || true)
INSTALL_DB_BIN=$(command -v mariadb-install-db || command -v mysql_install_db || true)
MYSQL_ADMIN_BIN=$(command -v mariadb-admin || command -v mysqladmin || true)
MYSQL_CLIENT_BIN=$(command -v mariadb || command -v mysql || true)

if [ -z "$MARIADB_DAEMON" ]; then
  echo "ERROR: Unable to locate MariaDB server binary (mariadbd or mysqld)." >&2
  exit 1
fi

if [ -z "$MYSQL_ADMIN_BIN" ] || [ -z "$MYSQL_CLIENT_BIN" ]; then
  echo "ERROR: Missing mariadb-admin/mysqladmin or mariadb/mysql client binaries." >&2
  exit 1
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
  mkdir -p /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
  if [ -n "$INSTALL_DB_BIN" ]; then
    echo "Running $INSTALL_DB_BIN to initialize database..."
    "$INSTALL_DB_BIN" --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal --skip-test-db
  else
    echo "Running $MARIADB_DAEMON --initialize to bootstrap database..."
    "$MARIADB_DAEMON" --initialize --user=mysql --datadir=/var/lib/mysql
  fi

  "$MARIADB_DAEMON" --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &

  for i in $(seq 1 30); do
    if "$MYSQL_ADMIN_BIN" --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  "$MYSQL_CLIENT_BIN" --socket=/run/mysqld/mysqld.sock <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

  "$MYSQL_ADMIN_BIN" --socket=/run/mysqld/mysqld.sock shutdown

  wait || true
fi

echo "Starting MariaDB server"
exec "$MARIADB_DAEMON" --user=mysql --datadir=/var/lib/mysql
