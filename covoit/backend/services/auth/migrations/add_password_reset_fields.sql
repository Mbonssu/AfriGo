-- Migration: Ajouter les champs pour la réinitialisation de mot de passe
-- Date: 2026-05-06

-- Ajouter les colonnes reset_token et reset_token_expires à la table users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS reset_token VARCHAR(255),
ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP;

-- Créer un index sur reset_token pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);

-- Commentaires
COMMENT ON COLUMN users.reset_token IS 'Token de réinitialisation de mot de passe (expire après 1 heure)';
COMMENT ON COLUMN users.reset_token_expires IS 'Date d''expiration du token de réinitialisation';
