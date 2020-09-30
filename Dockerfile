FROM php:7.4-apache

# 1. development packages
RUN apt-get update && apt-get install -y \
    git \
    zip \
    curl \
    sudo \
    nano \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libonig-dev \
    libreadline-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    g++ \
    pkg-config \
    build-essential \
    libmemcached-dev \
    libmemcached-tools \
    memcached

# 2. apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    gd \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    pdo_mysql \
    soap \
    zip

# 5. composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. configuring xdebug
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.profiler_enable_trigger=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.profiler_output_dir=\"/var/www/profiler\"" >> /usr/local/etc/php/conf.d/xdebug.ini

# 7. memcached
RUN git clone https://github.com/php-memcached-dev/php-memcached.git
RUN cd php-memcached && git checkout tags/v3.1.5 && phpize && ./configure --disable-memcached-sasl && make && make install
RUN echo 'extension = memcached.so' > /usr/local/etc/php/conf.d/memcached.ini

# 8. mongodb php extension
RUN pecl install mongodb \
    &&  echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongo.ini
