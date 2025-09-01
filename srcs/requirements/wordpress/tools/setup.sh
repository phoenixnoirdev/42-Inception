#!/bin/bash
set -e

# Copier les secrets dans /tmp lisible par www-data
cp /run/secrets/wordpress_db_user /tmp/wp_db_user
cp /run/secrets/wordpress_db_password /tmp/wp_db_password
chmod 400 /tmp/wp_db_*

# Définir les variables d'environnement pour WordPress (_FILE permet au wp-config.php standard de les lire)
export WORDPRESS_DB_USER_FILE=/tmp/wp_db_user
export WORDPRESS_DB_PASSWORD_FILE=/tmp/wp_db_password

# Lire les secrets pour les logs et sed
DB_USER_LOG="$(cat /tmp/wp_db_user)"
DB_PASSWORD_LOG="$(cat /tmp/wp_db_password)"

# Séparer l'hôte et le port
DB_HOST=${WORDPRESS_DB_HOST%%:*}
DB_PORT=${WORDPRESS_DB_HOST##*:}

# Log complet avec les secrets
#echo "[DEBUG] WORDPRESS_DB_USER='$DB_USER_LOG'"
#echo "[DEBUG] WORDPRESS_DB_PASSWORD='$DB_PASSWORD_LOG'"
#echo "[DEBUG] DB_HOST='$DB_HOST'"
#echo "[DEBUG] DB_PORT='$DB_PORT'"

# Attendre que MariaDB soit prêt
until mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER_LOG" -p"$DB_PASSWORD_LOG" --ssl=0 -e ";" 2>/dev/null; do
    echo "⏳ En attente de MariaDB..."
    sleep 2
done

echo "✅ MariaDB prête, mise à jour du wp-config.php"


# Mettre à jour wp-config.php pour utiliser les secrets lus
WP_CONFIG=/var/www/html/wp-config.php
sed -i "s/define( 'DB_USER'.*/define( 'DB_USER', '${DB_USER_LOG}' );/" $WP_CONFIG
sed -i "s/define( 'DB_PASSWORD'.*/define( 'DB_PASSWORD', '${DB_PASSWORD_LOG}' );/" $WP_CONFIG

# Ajouter MYSQL_CLIENT_FLAGS après DB_HOST
if ! grep -q "MYSQL_CLIENT_FLAGS" "$WP_CONFIG"; then
    sed -i "/define( 'DB_HOST'/a define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT );" "$WP_CONFIG"
fi

echo "✅ Secrets injectés dans wp-config.php"


# Nettoyer les fichiers temporaires
rm -f /tmp/wp_db_*


echo "✅ MariaDB prête, lancement de WordPress"

# Lancer WordPress via l'entrypoint officiel
exec docker-entrypoint.sh "$@"