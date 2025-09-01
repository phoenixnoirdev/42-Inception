#!/bin/bash

DB_USER=$(cat /run/secrets/mysql_user)
DB_PASS=$(cat /run/secrets/mysql_password)
ROOT_PASS=$(cat /run/secrets/mysql_root_password)
DB_NAME=${MYSQL_DATABASE}

mkdir -p /run/mysqld /var/log/mysql
chown -R mysql:mysql /run/mysqld /var/log/mysql

# 1. Démarrer MariaDB avec skip-grant-tables (pas de vérification des privilèges)
mariadbd --skip-grant-tables --socket=/run/mysqld/mysqld.sock &
pid=$!

timeout=30
while ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
  timeout=$((timeout - 1))
  if [ $timeout -le 0 ]; then
    echo "MariaDB ne démarre pas, échec."
    exit 1
  fi
  sleep 1
done

# 2. Créer la base seulement (pas de création d'utilisateur ici)
mysql -u root <<-EOSQL
  CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
EOSQL

# 3. Arrêter le serveur temporaire
mysqladmin shutdown --socket=/run/mysqld/mysqld.sock
wait $pid 2>/dev/null

# 4. Relancer MariaDB normalement (avec privilèges)
mariadbd --user=mysql --socket=/run/mysqld/mysqld.sock --console &
pid=$!

timeout=30
while ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
  timeout=$((timeout - 1))
  if [ $timeout -le 0 ]; then
    echo "MariaDB normal ne démarre pas, échec."
    exit 1
  fi
  sleep 1
done

# 5. Créer utilisateur, modifier root, et flush
mysql -u root -p"${ROOT_PASS}" <<-EOSQL
  CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
  GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
  FLUSH PRIVILEGES;
EOSQL

# 6. Arrêter le serveur en arrière-plan
mysqladmin -u root -p"${ROOT_PASS}" shutdown --socket=/run/mysqld/mysqld.sock
wait $pid 2>/dev/null

# 7. Démarrer MariaDB au premier plan (mode container)
exec mariadbd --user=mysql --console