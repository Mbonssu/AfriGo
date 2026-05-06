#!/bin/bash
# Script pour vider toutes les tables de toutes les bases de données

CONTAINER_NAME="c58e1cfb2627_covoit-postgres"
POSTGRES_USER="covoit"

# Liste des bases de données
DATABASES=("auth_db" "user_db" "trip_db" "booking_db" "payment_db" "notification_db" "chat_db" "subscription_db" "caution_db" "forum_db" "tracking_db")

echo "🗑️  Vidage de toutes les tables..."

for DB in "${DATABASES[@]}"; do
    echo ""
    echo "📦 Base de données: $DB"
    
    # Récupérer toutes les tables de la base de données
    TABLES=$(docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER -d $DB -t -c "SELECT tablename FROM pg_tables WHERE schemaname='public';" | tr -d '\r' | xargs)
    
    if [ -z "$TABLES" ]; then
        echo "   ℹ️  Aucune table trouvée"
        continue
    fi
    
    echo "   Tables trouvées: $TABLES"
    
    # Vider chaque table
    for TABLE in $TABLES; do
        echo "   🧹 Vidage de la table: $TABLE"
        docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER -d $DB -c "TRUNCATE TABLE $TABLE CASCADE;" 2>/dev/null
    done
    
    echo "   ✅ $DB vidée"
done

echo ""
echo "✅ Toutes les bases de données ont été vidées !"
