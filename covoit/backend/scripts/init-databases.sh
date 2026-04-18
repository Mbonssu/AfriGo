#!/bin/bash
set -e

# Créer les bases de données pour chaque microservice
for db in auth_db user_db trip_db booking_db payment_db notification_db chat_db subscription_db caution_db forum_db tracking_db; do
  echo "Creating database: $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
done

echo "All databases created successfully."
