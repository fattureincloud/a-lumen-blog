#!/bin/bash

echo "Make storage directories"
cd /var/www/html/storage
mkdir -p app
mkdir -p framework/cache
mkdir -p framework/views
mkdir -p logs
chmod -R 777 /var/www/html/storage

if [ $XDEBUG_ENABLE -eq 0 ]; then
  echo "Remove XDebug"
  rm -rf /usr/local/etc/php/conf.d/xdebug.ini
fi

cd /var/www/html

echo "Launch memcached service"
service memcached start

echo "Launch apache2 foreground"
docker-php-entrypoint apache2-foreground
