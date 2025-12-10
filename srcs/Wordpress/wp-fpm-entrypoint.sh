#!/bin/sh
set -e


if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ] || [ -z "$WORDPRESS_DB_NAME" ]; then
  echo "ERROR: WORDPRESS_DB_* environment variables must be set."
  echo "Required: WORDPRESS_DB_HOST, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD, WORDPRESS_DB_NAME"
  exit 1
fi

if [ -n "$WORDPRESS_ADMIN_USER" ] && printf '%s' "$WORDPRESS_ADMIN_USER" | grep -qi 'admin'; then
  echo "ERROR: WORDPRESS_ADMIN_USER must not contain the substring 'admin'." >&2
  exit 1
fi

RUNTIME_SWITCH=$(command -v su-exec || command -v gosu || true)
if [ -z "$RUNTIME_SWITCH" ]; then
  echo "ERROR: Neither su-exec nor gosu is available to drop privileges." >&2
  exit 1
fi

wp_cli() {
  "$RUNTIME_SWITCH" www-data wp --path="$WP_PATH" "$@" --allow-root
}


WP_PATH=${WP_PATH:-/var/www/html}
WORDPRESS_DB_PORT=${WORDPRESS_DB_PORT:-3306}
DB_HOST_WITH_PORT="$WORDPRESS_DB_HOST"
if [ -n "$WORDPRESS_DB_PORT" ]; then
  DB_HOST_WITH_PORT="$WORDPRESS_DB_HOST:$WORDPRESS_DB_PORT"
fi

# Wait for MariaDB to accept connections
echo "Waiting for MariaDB at $DB_HOST_WITH_PORT..."
for i in $(seq 1 30); do
  if mysqladmin --host="$WORDPRESS_DB_HOST" --port="$WORDPRESS_DB_PORT" --user="$WORDPRESS_DB_USER" --password="$WORDPRESS_DB_PASSWORD" ping >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = 30 ]; then
    echo "ERROR: Unable to reach MariaDB after 30 attempts." >&2
    exit 1
  fi
  sleep 2
done

mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH"

# Ensure WP-CLI cache directory exists and writable
mkdir -p /var/www/.wp-cli/cache
chown -R www-data:www-data /var/www/.wp-cli


if [ ! -f "$WP_PATH/wp-settings.php" ]; then
  echo "Downloading WordPress to $WP_PATH..."
  wp_cli core download
fi


if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "Generating wp-config.php..."
  wp_cli config create \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="$DB_HOST_WITH_PORT" \
    --skip-check
fi


if [ -n "$WORDPRESS_URL" ] && [ -n "$WORDPRESS_TITLE" ] && [ -n "$WORDPRESS_ADMIN_USER" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ] && [ -n "$WORDPRESS_ADMIN_EMAIL" ]; then
  if ! wp_cli core is-installed >/dev/null 2>&1; then
    echo "Installing WordPress site..."
    wp_cli core install \
      --url="$WORDPRESS_URL" \
      --title="$WORDPRESS_TITLE" \
      --admin_user="$WORDPRESS_ADMIN_USER" \
      --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
      --admin_email="$WORDPRESS_ADMIN_EMAIL" \
      --skip-email
  fi
fi

if wp_cli core is-installed >/dev/null 2>&1; then
  if [ -n "$WORDPRESS_URL" ]; then
    wp_cli option update home "$WORDPRESS_URL" >/dev/null 2>&1 || true
    wp_cli option update siteurl "$WORDPRESS_URL" >/dev/null 2>&1 || true
  fi

  if [ -n "$WORDPRESS_ADMIN_USER" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ] && [ -n "$WORDPRESS_ADMIN_EMAIL" ]; then
    if wp_cli user get "$WORDPRESS_ADMIN_USER" >/dev/null 2>&1; then
      wp_cli user update "$WORDPRESS_ADMIN_USER" --user_email="$WORDPRESS_ADMIN_EMAIL" --user_pass="$WORDPRESS_ADMIN_PASSWORD" --display_name="$WORDPRESS_ADMIN_USER" >/dev/null 2>&1 || true
      wp_cli user add-role "$WORDPRESS_ADMIN_USER" administrator >/dev/null 2>&1 || true
    else
      wp_cli user create "$WORDPRESS_ADMIN_USER" "$WORDPRESS_ADMIN_EMAIL" --role=administrator --user_pass="$WORDPRESS_ADMIN_PASSWORD" >/dev/null 2>&1
    fi
  fi

  if [ -n "$WORDPRESS_SECONDARY_USER" ] && [ -n "$WORDPRESS_SECONDARY_EMAIL" ] && [ -n "$WORDPRESS_SECONDARY_PASSWORD" ]; then
    SECONDARY_ROLE=${WORDPRESS_SECONDARY_ROLE:-author}
    if wp_cli user get "$WORDPRESS_SECONDARY_USER" >/dev/null 2>&1; then
      wp_cli user update "$WORDPRESS_SECONDARY_USER" --user_email="$WORDPRESS_SECONDARY_EMAIL" --user_pass="$WORDPRESS_SECONDARY_PASSWORD" >/dev/null 2>&1 || true
      wp_cli user set-role "$WORDPRESS_SECONDARY_USER" "$SECONDARY_ROLE" >/dev/null 2>&1 || true
    else
      wp_cli user create "$WORDPRESS_SECONDARY_USER" "$WORDPRESS_SECONDARY_EMAIL" --role="$SECONDARY_ROLE" --user_pass="$WORDPRESS_SECONDARY_PASSWORD" >/dev/null 2>&1
    fi
  fi
fi

chown -R www-data:www-data "$WP_PATH"

echo "Starting php-fpm..."
exec php-fpm -F
