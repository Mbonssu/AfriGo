-- Script pour activer le statut Prime d'un utilisateur
-- Usage: Remplacer 'USER_ID_HERE' par l'ID de l'utilisateur

-- 1. Activer Prime dans le profil utilisateur (user_db)
\c user_db;

UPDATE driver_profiles 
SET is_prime = true,
    updated_at = NOW()
WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

-- Vérifier
SELECT user_id, is_prime, created_at, updated_at 
FROM driver_profiles 
WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

-- 2. Créer un abonnement actif (subscription_db)
\c subscription_db;

-- Supprimer les anciens abonnements si existants
DELETE FROM subscriptions WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

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
    '275a4f3e-9eb6-43db-a12d-b668fa3004b0',
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

-- Vérifier
SELECT id, user_id, plan_type, status, start_date, end_date, amount
FROM subscriptions 
WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

-- 3. Mettre à jour les trajets existants pour qu'ils soient Prime (trip_db)
\c trip_db;

UPDATE trips 
SET is_prime = true,
    updated_at = NOW()
WHERE driver_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

-- Vérifier
SELECT id, driver_id, departure_city, arrival_city, is_prime, status
FROM trips 
WHERE driver_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0';

-- Résumé
\c user_db;
SELECT 'USER PROFILE' as table_name, user_id, is_prime FROM driver_profiles WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0'
UNION ALL
SELECT 'SUBSCRIPTION', user_id::text, (status = 'active')::text FROM subscription_db.subscriptions WHERE user_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0'
UNION ALL
SELECT 'TRIPS', driver_id::text, COUNT(*)::text || ' trajets Prime' FROM trip_db.trips WHERE driver_id = '275a4f3e-9eb6-43db-a12d-b668fa3004b0' AND is_prime = true GROUP BY driver_id;
