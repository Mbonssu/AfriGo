-- Migration pour ajouter les colonnes KYC à la table user_profiles
-- Date: 2026-05-06

\c user_db;

-- Ajouter les colonnes KYC si elles n'existent pas
DO $$ 
BEGIN
    -- kyc_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='kyc_status') THEN
        ALTER TABLE user_profiles ADD COLUMN kyc_status VARCHAR DEFAULT 'none';
        RAISE NOTICE 'Colonne kyc_status ajoutée';
    ELSE
        RAISE NOTICE 'Colonne kyc_status existe déjà';
    END IF;

    -- cni_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='cni_type') THEN
        ALTER TABLE user_profiles ADD COLUMN cni_type VARCHAR;
        RAISE NOTICE 'Colonne cni_type ajoutée';
    ELSE
        RAISE NOTICE 'Colonne cni_type existe déjà';
    END IF;

    -- cni_number
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='cni_number') THEN
        ALTER TABLE user_profiles ADD COLUMN cni_number VARCHAR;
        RAISE NOTICE 'Colonne cni_number ajoutée';
    ELSE
        RAISE NOTICE 'Colonne cni_number existe déjà';
    END IF;

    -- cni_photo_url
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='cni_photo_url') THEN
        ALTER TABLE user_profiles ADD COLUMN cni_photo_url VARCHAR;
        RAISE NOTICE 'Colonne cni_photo_url ajoutée';
    ELSE
        RAISE NOTICE 'Colonne cni_photo_url existe déjà';
    END IF;

    -- selfie_url
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='selfie_url') THEN
        ALTER TABLE user_profiles ADD COLUMN selfie_url VARCHAR;
        RAISE NOTICE 'Colonne selfie_url ajoutée';
    ELSE
        RAISE NOTICE 'Colonne selfie_url existe déjà';
    END IF;

    -- face_match_score
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_profiles' AND column_name='face_match_score') THEN
        ALTER TABLE user_profiles ADD COLUMN face_match_score FLOAT;
        RAISE NOTICE 'Colonne face_match_score ajoutée';
    ELSE
        RAISE NOTICE 'Colonne face_match_score existe déjà';
    END IF;
END $$;

-- Vérifier les colonnes
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;
