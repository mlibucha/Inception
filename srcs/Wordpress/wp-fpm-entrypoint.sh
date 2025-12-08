#!/bin/sh
set -e


if [ -z "$WORDPRESS_DB_HOST" ] || [ -z "$WORDPRESS_DB_USER" ] || [ -z "$WORDPRESS_DB_PASSWORD" ] || [ -z "$WORDPRESS_DB_NAME" ]; then
  echo "ERROR: WORDPRESS_DB_* environment variables must be set."
  echo "Required: WORDPRESS_DB_HOST, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD, WORDPRESS_DB_NAME"
  exit 1
fi


WP_PATH=${WP_PATH:-/var/www/html}

mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH"

# Ensure WP-CLI cache directory exists and writable
mkdir -p /var/www/.wp-cli/cache
chown -R www-data:www-data /var/www/.wp-cli


if [ ! -f "$WP_PATH/wp-settings.php" ]; then
  echo "Downloading WordPress to $WP_PATH..."
  gosu www-data wp core download --path="$WP_PATH" --allow-root || wp core download --path="$WP_PATH" --allow-root
fi


if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "Generating wp-config.php..."
  gosu www-data wp config create \
    --path="$WP_PATH" \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --skip-check --allow-root || wp config create \
    --path="$WP_PATH" \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --skip-check --allow-root
fi


if [ -n "$WORDPRESS_URL" ] && [ -n "$WORDPRESS_TITLE" ] && [ -n "$WORDPRESS_ADMIN_USER" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ] && [ -n "$WORDPRESS_ADMIN_EMAIL" ]; then
  if ! gosu www-data wp core is-installed --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    echo "Installing WordPress site..."
    gosu www-data wp core install \
      --path="$WP_PATH" \
      --url="$WORDPRESS_URL" \
      --title="$WORDPRESS_TITLE" \
      --admin_user="$WORDPRESS_ADMIN_USER" \
      --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
      --admin_email="$WORDPRESS_ADMIN_EMAIL" \
      --skip-email --allow-root || wp core install \
      --path="$WP_PATH" \
      --url="$WORDPRESS_URL" \
      --title="$WORDPRESS_TITLE" \
      --admin_user="$WORDPRESS_ADMIN_USER" \
      --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
      --admin_email="$WORDPRESS_ADMIN_EMAIL" \
      --skip-email --allow-root
  fi
fi

chown -R www-data:www-data "$WP_PATH"

echo "Starting php-fpm..."
exec php-fpm -F
