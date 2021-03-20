FROM php:7.4-apache

# Install PHP and composer dependencies
RUN apt-get update
RUN apt-get install -y git curl libmcrypt-dev libjpeg-dev libpng-dev libonig-dev libfreetype6-dev libbz2-dev libzip-dev zip unzip

ENV APP_HOME /var/www/html

# Fix permissions
RUN chmod 1777 /tmp

# Change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    opcache \
    pdo_mysql \
    mysqli \
    zip

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug
RUN echo "xdebug.start_with_request=yes" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.discover_client_host=1" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=BEST_IDE" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.client_host=host.docker.internal" >> $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
