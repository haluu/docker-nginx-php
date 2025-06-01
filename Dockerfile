FROM alpine:3.19
LABEL Maintainer="aluu"
LABEL Description="Lightweight container with Nginx & PHP based on Alpine Linux"


# Install PHP, nginx, and supervisor packages
RUN apk add --no-cache \
    curl \
    nginx \
    php84 \
    php84-fpm \
    php84-mysqli \
    php84-json \
    php84-openssl \
    php84-curl \
    php84-zlib \
    php84-xml \
    php84-phar \
    php84-intl \
    php84-dom \
    php84-xmlreader \
    php84-ctype \
    php84-session \
    php84-mbstring \
    php84-opcache \
    supervisor 

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php84 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php84/php-fpm.d/www.conf
COPY config/php.ini /etc/php84/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Add volume
VOLUME ["/var/www/html"]

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping