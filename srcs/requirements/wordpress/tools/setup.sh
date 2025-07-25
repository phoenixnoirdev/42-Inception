#!/bin/bash

# Lecture des secrets et injection dans les variables que WordPress
export WORDPRESS_DB_USER=$(cat /run/secrets/wordpress_db_user)
export WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wordpress_db_password)

# Séparer hôte et port
DB_HOST=${WORDPRESS_DB_HOST%%:*}
DB_PORT=${WORDPRESS_DB_HOST##*:}

# Log des variables (sans afficher les mots de passe)
#echo "[DEBUG] WORDPRESS_DB_USER='$WORDPRESS_DB_USER'"
#echo "[DEBUG] WORDPRESS_DB_PASSWORD='$WORDPRESS_DB_PASSWORD'"
#echo "[DEBUG] DB_HOST='$DB_HOST'"
#echo "[DEBUG] DB_PORT='$DB_PORT'"

# Attendre que MariaDB soit prêt en tentant une connexion mysql
until mysql -h"$DB_HOST" -P"$DB_PORT" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e ";" 2>/dev/null; do
  echo "⏳ En attente de MariaDB..."
  sleep 2
done

# Lancer WordPress
echo "✅ Lancement de WordPress"
exec docker-entrypoint.sh "$@"
