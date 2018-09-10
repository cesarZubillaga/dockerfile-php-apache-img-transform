FROM php:7.1-apache
RUN apt-get update && apt-get install -y zlib1g-dev libicu-dev g++ && apt-get install -y git zip && docker-php-ext-install zip
RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
 && echo "date.timezone 'UTC'" > "$PHP_INI_DIR/conf.d/date_timezone.ini"  \
 && a2enmod rewrite
#installation of gd
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.6.5

RUN curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/b107d959a5924af895807021fcef4ffec5a76aa9/web/installer \
 && php -r " \
    \$signature = '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
 && composer --ansi --version --no-interaction \
 && rm -rf /tmp/* /tmp/.htaccess

# PHP INI CONFIGURATIONS
# COPY config/php.ini /usr/local/etc/php
COPY 000-default.conf /etc/apache2/sites-available
COPY default-ssl.conf /etc/apache2/sites-available

CMD bash -c "composer install && /usr/sbin/apache2ctl -D FOREGROUND"
