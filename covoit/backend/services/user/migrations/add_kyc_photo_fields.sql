-- Migration: Add KYC photo fields to user_profiles
-- Date: 2026-05-06

-- Add license photo URL for drivers
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS license_photo_url VARCHAR(500);

-- Add registration card photo URL (carte grise)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS registration_card_url VARCHAR(500);

-- Add comment for clarity
COMMENT ON COLUMN user_profiles.license_photo_url IS 'URL of driver license photo';
COMMENT ON COLUMN user_profiles.registration_card_url IS 'URL of vehicle registration card (carte grise)';
