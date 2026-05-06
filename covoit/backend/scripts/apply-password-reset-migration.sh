#!/bin/bash

# Script pour appliquer la migration de réinitialisation de mot de passe
# et redémarrer le service d'authentification

set -e

echo "🔄 Application de la migration pour la réinitialisation de mot de passe..."

# Appliquer la migration sur la base de données auth_db
docker exec -i postgres-db psql -U postgres -d auth_db < backend/services/auth/migrations/add_password_reset_fields.sql

echo "✅ Migration appliquée avec succès!"

echo "🔄 Redémarrage du service d'authentification..."
docker-compose restart auth-service

echo "⏳ Attente du démarrage du service..."
sleep 5

echo "✅ Service d'authentification redémarré!"
echo ""
echo "📋 Vérification de l'état des services:"
docker-compose ps auth-service api-gateway

echo ""
echo "✅ Tout est prêt! Vous pouvez maintenant tester la fonctionnalité de mot de passe oublié."
