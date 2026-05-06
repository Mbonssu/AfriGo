#!/bin/bash

# Script pour activer le statut Prime d'un utilisateur
# Usage: ./activate-prime.sh [USER_ID]

set -e

USER_ID="${1:-275a4f3e-9eb6-43db-a12d-b668fa3004b0}"

echo "🌟 Activation du statut Prime pour l'utilisateur: $USER_ID"
echo "=================================================="
echo ""

# Exécuter le script SQL
docker exec -i covoit-postgres psql -U covoit <<EOF
-- 1. Activer Prime dans le profil utilisateur (user_db)
\c user_db;

UPDATE driver_profiles 
SET is_prime = true,
    updated_at = NOW()
WHERE user_id = '$USER_ID';

SELECT '✅ Profil chauffeur mis à jour' as status;

-- 2. Créer un abonnement actif (subscription_db)
\c subscription_db;

-- Supprimer les anciens abonnements si existants
DELETE FROM subscriptions WHERE user_id = '$USER_ID';

-- Créer un nouvel abonnement Prime (trimestriel)
INSERT INTO subscriptions (
    id,
    user_id,
    plan_type,
    status,
    start_date,
    end_date,
    amount,
    payment_method,
    auto_renew,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '$USER_ID',
    'quarterly',
    'active',
    NOW(),
    NOW() + INTERVAL '3 months',
    12000,
    'simulation',
    true,
    NOW(),
    NOW()
);

SELECT '✅ Abonnement créé' as status;

-- 3. Mettre à jour les trajets existants pour qu'ils soient Prime (trip_db)
\c trip_db;

UPDATE trips 
SET is_prime = true,
    updated_at = NOW()
WHERE driver_id = '$USER_ID';

SELECT '✅ Trajets mis à jour' as status;

-- Résumé
\c user_db;
\echo ''
\echo '📊 RÉSUMÉ:'
\echo '=========='

SELECT 
    'Profil Prime' as info,
    CASE WHEN is_prime THEN '✅ Activé' ELSE '❌ Désactivé' END as statut
FROM driver_profiles 
WHERE user_id = '$USER_ID';

\c subscription_db;
SELECT 
    'Abonnement' as info,
    plan_type || ' - ' || status as statut
FROM subscriptions 
WHERE user_id = '$USER_ID'
ORDER BY created_at DESC
LIMIT 1;

\c trip_db;
SELECT 
    'Trajets Prime' as info,
    COUNT(*)::text || ' trajet(s)' as statut
FROM trips 
WHERE driver_id = '$USER_ID' AND is_prime = true;

EOF

echo ""
echo "🎉 Statut Prime activé avec succès !"
echo "🔄 Redémarrez l'application Flutter pour voir les changements."
