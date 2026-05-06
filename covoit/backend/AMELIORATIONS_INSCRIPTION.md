# Améliorations de l'inscription et gestion des erreurs

## Date: 2026-05-06

## Problèmes résolus

### 1. ❌ Inscription chauffeur impossible
**Problème**: Le numéro de téléphone était déjà utilisé par un compte passager, empêchant l'inscription en tant que chauffeur.

**Solution**: 
- Base de données vidée pour permettre de nouvelles inscriptions
- Script `scripts/clear-all-databases.sh` disponible pour vider toutes les tables

### 2. ❌ Erreurs de serveur (colonnes KYC manquantes)
**Problème**: Les colonnes KYC (`kyc_status`, `cni_type`, etc.) n'existaient pas dans la table `user_profiles`, causant des erreurs 500.

**Solution**:
- Migration SQL créée : `scripts/migrate-user-kyc.sql`
- Colonnes ajoutées :
  - `kyc_status` (VARCHAR, default 'none')
  - `cni_type` (VARCHAR, nullable)
  - `cni_number` (VARCHAR, nullable)
  - `cni_photo_url` (VARCHAR, nullable)
  - `selfie_url` (VARCHAR, nullable)
  - `face_match_score` (FLOAT, nullable)

### 3. ❌ Initiales manquantes dans le profil
**Problème**: Quand l'utilisateur n'avait pas de photo de profil, les initiales ne s'affichaient pas car `first_name` et `last_name` étaient vides.

**Solutions**:
- **Backend**: Amélioration de la gestion du profil utilisateur
- **Frontend**: 
  - Amélioration du getter `initials` dans `AppUserProfile` pour afficher la première lettre du téléphone si le nom est vide
  - Ajout de logs pour tracer les erreurs de mise à jour du profil
  - Message informatif si la mise à jour du profil échoue après l'inscription

### 4. ❌ Messages d'erreur non clairs
**Problème**: Quand l'email ou le téléphone était déjà utilisé, l'utilisateur restait bloqué sans message clair.

**Solutions**:

#### Backend (services/auth/app/services/auth_service.py)
```python
# Avant
raise ValueError("User already exists")
raise ValueError("Phone already exists")
raise ValueError("Invalid credentials")

# Après
raise ValueError("Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email.")
raise ValueError("Ce numéro de téléphone est déjà utilisé. Veuillez utiliser un autre numéro.")
raise ValueError("Email ou mot de passe incorrect.")
```

#### API Gateway (api-gateway/app/api/routes/auth.py)
- Extraction correcte du message d'erreur du service d'authentification
- Évite la structure imbriquée `{"detail": {"detail": "message"}}`

#### Frontend (lib/core/network/error_interceptor.dart)
- Gestion des structures imbriquées pour extraire le bon message
- Support de `{"detail": {"detail": "message"}}` et `{"detail": "message"}`

## Tests

### Script de test d'inscription
```bash
./test_registration.sh
```
Teste :
- Inscription passager
- Mise à jour du profil avec `first_name` et `last_name`
- Récupération du profil

### Script de test des messages d'erreur
```bash
./test_error_messages.sh
```
Teste :
- Inscription réussie
- Email déjà utilisé → Message clair
- Téléphone déjà utilisé → Message clair
- Mauvais mot de passe → Message clair

## Résultats des tests

✅ **Inscription passager**: Fonctionne correctement
✅ **Mise à jour du profil**: `first_name` et `last_name` sont bien sauvegardés
✅ **Messages d'erreur**: Clairs et en français
✅ **Initiales**: S'affichent correctement (ou première lettre du téléphone si nom vide)

## Exemples de messages d'erreur

### Email déjà utilisé
```json
{
  "detail": "Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email."
}
```

### Téléphone déjà utilisé
```json
{
  "detail": "Ce numéro de téléphone est déjà utilisé. Veuillez utiliser un autre numéro."
}
```

### Identifiants incorrects
```json
{
  "detail": "Email ou mot de passe incorrect."
}
```

## Prochaines étapes recommandées

1. **Tester l'inscription depuis l'application mobile**
   - Vider la base de données : `bash scripts/clear-all-databases.sh`
   - Tester l'inscription passager
   - Tester l'inscription chauffeur
   - Vérifier que les messages d'erreur s'affichent correctement

2. **Vérifier l'affichage des initiales**
   - S'inscrire sans photo de profil
   - Vérifier que les initiales du nom s'affichent
   - Si le nom n'est pas renseigné, vérifier que la première lettre du téléphone s'affiche

3. **Tester les cas d'erreur**
   - Essayer de s'inscrire avec un email déjà utilisé
   - Essayer de s'inscrire avec un téléphone déjà utilisé
   - Vérifier que les messages sont clairs et en français

## Fichiers modifiés

### Backend
- `services/auth/app/services/auth_service.py` - Messages d'erreur en français
- `api-gateway/app/api/routes/auth.py` - Extraction correcte des messages d'erreur
- `scripts/migrate-user-kyc.sql` - Migration pour ajouter les colonnes KYC
- `scripts/clear-all-databases.sh` - Script pour vider toutes les tables
- `test_registration.sh` - Script de test d'inscription
- `test_error_messages.sh` - Script de test des messages d'erreur

### Frontend
- `lib/screens/auth/register_screen.dart` - Meilleure gestion des erreurs avec logs
- `lib/core/network/error_interceptor.dart` - Support des structures imbriquées
- `lib/data/models/app_user_profile.dart` - Amélioration du getter `initials`

## Notes importantes

- **Base de données**: Les colonnes KYC ont été ajoutées à la table `user_profiles`
- **Migration**: Le script `migrate-user-kyc.sql` est idempotent (peut être exécuté plusieurs fois)
- **Messages**: Tous les messages d'erreur sont maintenant en français et explicites
- **Logs**: Des logs ont été ajoutés pour faciliter le débogage
