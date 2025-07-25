FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /run/mysqld

RUN mkdir -p /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql

COPY ./conf/my.cnf /etc/mysql/my.cnf
COPY ./tools/script.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/script.sh"]
