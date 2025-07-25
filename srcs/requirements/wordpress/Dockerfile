FROM wordpress:php8.2-fpm

# Installer le client MySQL
RUN apt-get update && \
    apt-get install -y default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Installe nano
RUN apt-get update && \
    apt-get install -y nano && \
    rm -rf /var/lib/apt/lists/*

COPY ./tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

ENV WORDPRESS_DB_HOST=$WORDPRESS_DB_HOST
ENV WORDPRESS_DB_NAME=$WORDPRESS_DB_NAME

ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["php-fpm"]
