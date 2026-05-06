# Gestion des Photos - AfriGo

## Vue d'ensemble

Ce document décrit l'implémentation complète du système de gestion des photos dans l'application AfriGo.

## Architecture

### Backend

#### Services
- **FileService** (`backend/services/user/app/services/file_service.py`)
  - Upload de photos de profil
  - Upload de documents KYC (CNI, selfie, permis, carte grise)
  - Upload de photos de véhicules
  - Suppression de fichiers
  - Stockage dans `/app/uploads/` avec sous-dossiers :
    - `/profiles/` - Photos de profil
    - `/kyc/` - Documents d'identité
    - `/vehicles/` - Photos de véhicules

#### Base de données
- **Migration** : `backend/services/user/migrations/add_kyc_photo_fields.sql`
  - Ajout de `license_photo_url` (permis de conduire)
  - Ajout de `registration_card_url` (carte grise)

#### API Routes

**Service User** (`backend/services/user/app/api/routes/users.py`)
- `POST /users/{user_id}/profile-photo` - Upload photo de profil seule
- `PUT /users/{user_id}/profile` - Mise à jour profil avec photo optionnelle
- `POST /users/{user_id}/kyc/verify` - Upload documents KYC (CNI, selfie, permis, carte grise)

**API Gateway** (`backend/api-gateway/app/api/routes/users.py`)
- `POST /api/users/profile/{user_id}/photo` - Proxy upload photo
- `PUT /api/users/profile/{user_id}` - Proxy mise à jour profil
- `POST /api/users/profile/{user_id}/kyc/verify` - Proxy KYC
- `GET /api/users/uploads/profiles/{filename}` - Servir photos de profil
- `GET /api/users/uploads/kyc/{filename}` - Servir documents KYC
- `GET /api/users/uploads/vehicles/{filename}` - Servir photos de véhicules

### Frontend

#### Widgets Réutilisables

**UserAvatar** (`lib/widgets/user_avatar.dart`)
```dart
// Avatar simple
UserAvatar(
  photoUrl: profile.profilePictureUrl,
  initials: profile.initials,
  radius: 20,
)

// Avatar avec badge de vérification
VerifiedUserAvatar(
  photoUrl: profile.profilePictureUrl,
  initials: profile.initials,
  radius: 20,
  isVerified: true,
)

// Avatar avec badge Prime
PrimeUserAvatar(
  photoUrl: driver.profilePictureUrl,
  initials: driver.initials,
  radius: 20,
  isPrime: true,
)
```

**Caractéristiques** :
- Affiche la photo si disponible, sinon les initiales
- Gestion automatique des erreurs de chargement
- Construction automatique de l'URL complète
- Support des badges (vérification, Prime)
- Personnalisable (taille, couleurs)

#### Services

**MediaService** (`lib/core/services/media_service.dart`)
- `pickImage(source: ImageSource)` - Sélectionner une image (caméra ou galerie)
- `takePhoto()` - Prendre une photo avec la caméra
- `pickImageFromGallery()` - Choisir depuis la galerie
- `takeMultiplePhotos()` - Sélectionner plusieurs photos
- `showPhotoSourceDialog()` - Dialogue de choix caméra/galerie

#### Repositories

**UserRepository** (`lib/data/repositories/user_repository.dart`)
```dart
// Upload photo de profil seule
await userRepo.uploadProfilePhoto(
  userId: userId,
  photo: photoFile,
);

// Mise à jour profil avec photo
await userRepo.updateProfileWithPhoto(
  userId: userId,
  firstName: 'John',
  lastName: 'Doe',
  phone: '+237680808080',
  photo: photoFile, // optionnel
);

// Upload documents KYC
await userRepo.uploadKYCDocuments(
  userId: userId,
  cniPhoto: cniFile,
  selfie: selfieFile,
  licensePhoto: licenseFile, // optionnel
  registrationCard: registrationCardFile, // optionnel
);
```

#### Modèles de données

**AppUserProfile** (`lib/data/models/app_user_profile.dart`)
- `profilePictureUrl` - URL de la photo de profil
- `initials` - Initiales calculées automatiquement

**AppDriverProfile** (`lib/data/models/app_driver_profile.dart`)
- `profilePictureUrl` - URL de la photo de profil
- `initials` - Initiales calculées automatiquement

#### Écrans

**EditProfileScreen** (`lib/screens/edit_profile_screen.dart`)
- Modification de la photo de profil
- Modification du prénom, nom, téléphone
- Options : Caméra ou Galerie
- Validation des champs
- Upload automatique lors de la sauvegarde

**ProfileScreen** (`lib/screens/profile_screen.dart`)
- Affichage de la photo de profil
- Avatar cliquable pour éditer
- Menu "Modifier mon profil"

**RegisterScreen - Step 3** (`lib/screens/auth/register_screen.dart`)
- Upload de photo de profil lors de l'inscription
- Upload de CNI/Passeport
- Upload de permis (chauffeurs)
- Upload de carte grise (chauffeurs)
- Upload automatique après création du compte

## Flux d'utilisation

### 1. Modification du profil

```
Utilisateur → ProfileScreen → Clic sur avatar
  → EditProfileScreen → Sélection photo (caméra/galerie)
  → Aperçu local → Sauvegarde
  → Upload vers API → Mise à jour BDD
  → Invalidation cache → Rechargement profil
  → Affichage nouvelle photo
```

### 2. Inscription avec photos

```
Utilisateur → RegisterScreen → Step 1 (Rôle)
  → Step 2 (Informations) → Step 3 (Documents)
  → Sélection photos (CNI, profil, permis, carte grise)
  → Création compte → Upload profil
  → Upload photo de profil → Upload documents KYC
  → Redirection vers Home
```

### 3. Affichage des avatars

```
API → Profil avec profilePictureUrl
  → UserAvatar widget → Construction URL complète
  → NetworkImage → Chargement depuis API Gateway
  → Affichage photo OU initiales (fallback)
```

## URLs et Endpoints

### Construction des URLs

Les URLs de photos sont stockées en base sous forme relative :
```
/uploads/profiles/profile_5be815d9-3f93-4ce3-ac65-bed0723c966a_0b1dedea.png
```

Le widget `UserAvatar` construit automatiquement l'URL complète :
```
http://192.168.45.54:8000/api/users/uploads/profiles/profile_5be815d9-3f93-4ce3-ac65-bed0723c966a_0b1dedea.png
```

### Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/users/profile/{id}/photo` | Upload photo de profil |
| PUT | `/api/users/profile/{id}` | Mise à jour profil + photo |
| POST | `/api/users/profile/{id}/kyc/verify` | Upload documents KYC |
| GET | `/api/users/uploads/profiles/{filename}` | Récupérer photo de profil |
| GET | `/api/users/uploads/kyc/{filename}` | Récupérer document KYC |
| GET | `/api/users/uploads/vehicles/{filename}` | Récupérer photo véhicule |

## Sécurité

### Validation des fichiers

**Backend** :
- Types acceptés : `image/jpeg`, `image/png`, `image/webp`
- Taille maximale : 5 Mo (profil), 10 Mo (KYC)
- Noms de fichiers uniques (UUID)

**Frontend** :
- Compression automatique (max 1920x1080, qualité 85%)
- Validation du type avant upload
- Gestion des erreurs de chargement

### Stockage

- Fichiers stockés dans `/app/uploads/` (volume Docker)
- Séparation par type (profiles, kyc, vehicles)
- Noms de fichiers avec UUID pour éviter les collisions
- Suppression de l'ancienne photo lors du remplacement

## Tests

### Test manuel - Upload photo de profil

1. Se connecter à l'application
2. Aller dans Profil → Modifier mon profil
3. Cliquer sur l'avatar
4. Choisir "Prendre une photo" ou "Galerie"
5. Sélectionner une photo
6. Cliquer sur "Enregistrer"
7. Vérifier que la photo s'affiche dans le profil

### Test manuel - Inscription avec photos

1. Créer un nouveau compte
2. Étape 3 : Ajouter CNI, photo de profil, permis, carte grise
3. Terminer l'inscription
4. Vérifier que les photos sont uploadées
5. Vérifier que la photo de profil s'affiche

### Vérification backend

```bash
# Vérifier les fichiers uploadés
docker exec covoit-user ls -la /app/uploads/profiles/
docker exec covoit-user ls -la /app/uploads/kyc/

# Vérifier en base de données
docker exec -i c58e1cfb2627_covoit-postgres psql -U covoit -d user_db -c \
  "SELECT user_id, first_name, last_name, profile_picture_url FROM user_profiles LIMIT 5;"

# Tester l'accès aux images
curl -I http://192.168.45.54:8000/api/users/uploads/profiles/profile_xxx.png
```

## Dépendances

### Backend
- `aiofiles==23.2.1` - Opérations fichiers asynchrones
- `python-multipart` - Gestion multipart/form-data

### Frontend
- `image_picker` - Sélection photos caméra/galerie
- `path_provider` - Accès aux répertoires système
- `dio` - Upload multipart

## Améliorations futures

### Court terme
- [ ] Mettre à jour tous les avatars dans l'application
- [ ] Ajouter un indicateur de progression lors de l'upload
- [ ] Permettre le recadrage des photos avant upload
- [ ] Ajouter une prévisualisation avant sauvegarde

### Moyen terme
- [ ] Compression côté backend avec Pillow
- [ ] Génération de thumbnails (petite taille pour listes)
- [ ] Stockage sur S3/Cloud Storage en production
- [ ] Cache des images avec `cached_network_image`

### Long terme
- [ ] Détection de visages pour centrage automatique
- [ ] Filtres et retouches basiques
- [ ] Galerie de photos pour les véhicules
- [ ] Historique des photos de profil

## Troubleshooting

### La photo ne s'affiche pas

1. Vérifier que l'URL est correcte dans les logs :
   ```
   UserAvatar: photoUrl=/uploads/profiles/..., fullUrl=http://...
   ```

2. Vérifier que le fichier existe :
   ```bash
   docker exec covoit-user ls -la /app/uploads/profiles/
   ```

3. Vérifier l'accès via API Gateway :
   ```bash
   curl -I http://192.168.45.54:8000/api/users/uploads/profiles/profile_xxx.png
   ```

4. Vérifier les logs du service user :
   ```bash
   docker compose logs --tail=50 user-service
   ```

### Erreur 404 sur l'image

- Vérifier que l'URL contient `/api/users/` avant `/uploads/`
- Le widget `UserAvatar` ajoute automatiquement ce préfixe

### Upload échoue

- Vérifier la taille du fichier (max 5 Mo pour profil)
- Vérifier le format (JPEG, PNG, WebP uniquement)
- Vérifier les logs backend pour l'erreur exacte

## Auteurs

- Implémentation : Phase 2 - Mai 2026
- Application : AfriGo (Covoiturage Cameroun)
