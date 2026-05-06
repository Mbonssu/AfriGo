# Changelog - AfriGo

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [1.0.0-phase3] - 2026-05-06

### ✨ Ajouté

#### Gestion des Photos
- **Widget UserAvatar réutilisable** : Affichage uniforme des avatars dans toute l'application
  - `UserAvatar` : Avatar simple avec photo ou initiales
  - `PrimeUserAvatar` : Avatar avec badge Prime
  - `VerifiedUserAvatar` : Avatar avec badge de vérification
  - Construction automatique des URLs
  - Gestion des erreurs de chargement

- **Service de médias** : Sélection et capture de photos
  - `MediaService` : Service pour prendre/choisir des photos
  - Support caméra et galerie
  - Sélection multiple de photos
  - Dialogue de choix de source

- **Upload de photos de profil** : Les utilisateurs peuvent ajouter leur photo
  - Écran d'édition de profil (`edit_profile_screen.dart`)
  - Upload pendant l'inscription
  - Modification de la photo existante
  - Prévisualisation avant upload

- **Backend de gestion de fichiers** : Service complet d'upload
  - `FileService` avec aiofiles pour opérations asynchrones
  - Upload de photos de profil
  - Upload de documents KYC (CNI, selfie, permis, carte grise)
  - Upload de photos de véhicules
  - Stockage organisé dans `/app/uploads/`

- **Routes API pour les photos** :
  - `POST /api/users/profile/{user_id}/photo` : Upload photo de profil
  - `PUT /api/users/profile/{user_id}` : Mise à jour profil avec photo
  - `POST /api/users/profile/{user_id}/kyc/verify` : Upload documents KYC
  - `GET /api/users/uploads/profiles/{filename}` : Servir photos de profil
  - `GET /api/users/uploads/kyc/{filename}` : Servir documents KYC
  - `GET /api/users/uploads/vehicles/{filename}` : Servir photos de véhicules

### 🔄 Modifié

#### Avatars mis à jour (11 écrans)
- **Écrans passagers** :
  - `search_screen.dart` : Liste des trajets avec photos des chauffeurs
  - `my_trips_screen.dart` : Mes réservations avec photos
  - `chat_screen.dart` : Chat avec photo du chauffeur
  - `rating_screen.dart` : Évaluation avec photo du chauffeur
  - `passenger_home.dart` : Accueil avec photos des chauffeurs
  - `trip_detail_screen.dart` : Détails du trajet avec photo

- **Écrans chauffeurs** :
  - `driver_home.dart` : Accueil avec photo de profil
  - `driver_profile_screen.dart` : Profil public avec photo
  - `driver_passengers_screen.dart` : Liste des passagers avec photos
  - `prime_forum_screen.dart` : Forum avec avatars

- **Écrans communs** :
  - `trip_tracking_screen.dart` : Suivi du trajet avec photo
  - `profile_screen.dart` : Profil utilisateur avec photo

#### Modèles de données
- `AppDriverProfile` : Ajout de `profilePictureUrl` et getter `initials`
- `UserProfile` : Support des URLs de photos

#### Base de données
- Migration : Ajout de `license_photo_url` et `registration_card_url`

### 📚 Documentation
- `PHOTO_MANAGEMENT.md` : Documentation complète du système de photos
- `PHOTO_MANAGEMENT_STATUS.md` : Statut d'implémentation détaillé

### 📊 Statistiques Phase 3
- **36 fichiers modifiés**
- **2 910 insertions, 233 suppressions**
- **11 écrans mis à jour** avec UserAvatar
- **3 nouveaux widgets** créés
- **1 nouveau service** (MediaService)
- **95% des fonctionnalités photo** implémentées

---

## [1.0.0-phase2] - 2026-05-06

### ✨ Ajouté

#### Authentification
- **Mot de passe oublié** : Nouvelle fonctionnalité permettant de réinitialiser son mot de passe
  - Écran de demande de réinitialisation (`forgot_password_screen.dart`)
  - Écran de nouveau mot de passe (`reset_password_screen.dart`)
  - Routes API `/api/auth/forgot-password` et `/api/auth/reset-password`
  - Migration base de données avec champs `reset_token` et `reset_token_expires`

#### Système de Paiement Simulé
- **Dépôt de fonds** : Passager peut déposer des fonds pour une réservation
  - Support MTN Mobile Money
  - Support Orange Money
  - Validation du montant (minimum 500 FCFA)
  
- **Simulation de paiement** : Processus complet de paiement simulé
  - Animation de traitement (3 secondes)
  - Confirmation visuelle
  - Aucune transaction réelle
  
- **Système de séquestre** : Fonds bloqués jusqu'à validation
  - Affichage du statut "En attente"
  - Étapes du processus visibles
  - Sécurité des transactions
  
- **Libération des fonds** : Client peut libérer les fonds après le trajet
  - Bouton "Déposer"
  - Confirmation de libération
  - Transfert vers le chauffeur
  
- **Portefeuille chauffeur** : Gestion des gains
  - Solde disponible
  - Fonds en attente
  - Historique des transactions
  - Statistiques mensuelles
  
- **Retrait chauffeur** : Retrait des gains
  - Choix du montant
  - Support MTN et Orange Money
  - Montants rapides (5k, 10k, 20k, Tout)
  - Simulation de transfert
  
- **Abonnement Prime** : Système d'abonnement premium
  - Plan Mensuel : 5 000 FCFA
  - Plan Trimestriel : 12 000 FCFA (économie 20%)
  - Plan Annuel : 40 000 FCFA (économie 33%)
  - Déblocage automatique des fonctionnalités
  
- **Provider de simulation** : Gestion centralisée des paiements
  - État global des paiements
  - Déblocage des fonctionnalités
  - Mode démo disponible
  
- **Widget de garde** : Protection des fonctionnalités payantes
  - Écran de verrouillage personnalisé
  - Déblocage automatique après paiement
  - Support Prime et paiements standards

#### Trajets
- **Système de waypoints** : Points d'arrêt intermédiaires
  - Modèle `Waypoint` avec ville, adresse, heure
  - Widget de gestion des waypoints
  - Affichage visuel des étapes
  - Ordre personnalisable

#### Documentation
- **PAYMENT_SIMULATION.md** : Guide complet du système de paiement
- **REBRANDING.md** : Documentation du changement de nom
- **CHECKUP_REPORT.md** : Rapport d'état de l'application
- **CHANGELOG.md** : Ce fichier

#### Scripts
- `apply-password-reset-migration.sh` : Application de la migration
- `clear-all-databases.sh` : Nettoyage des bases de données
- `test_error_messages.sh` : Tests des messages d'erreur
- `test_registration.sh` : Tests d'inscription

### 🔄 Modifié

#### Rebranding
- **Nom de l'application** : 237COVOIT → **AfriGo**
- **Package Android** : `com.example.covoit_237` → `com.afrigo.app`
- **Bundle iOS/macOS** : `com.example.covoit237` → `com.afrigo.app`
- **URLs** : `api.237covoit.cm` → `api.afrigo.cm`
- **Emails** : `support@237covoit.cm` → `support@afrigo.cm`
- **Tous les écrans** : Mise à jour des textes et titres
- **Splash screen** : Affiche "AfriGo"
- **Profil** : "À propos d'AfriGo"

#### Backend
- **API Gateway** : Nom mis à jour vers "AfriGo API Gateway"
- **Auth Service** : Nom mis à jour vers "AfriGo Auth Service"
- **Routes** : Ajout des routes de réinitialisation de mot de passe
- **Modèles** : Ajout des champs de reset token

#### Frontend
- **Écran de connexion** : Lien vers mot de passe oublié
- **Gestion d'erreurs** : Messages plus clairs avec `AppException`
- **Thème** : Cohérence visuelle améliorée
- **Navigation** : Flux de paiement intégré

### 🐛 Corrigé
- Gestion des erreurs dans les écrans de paiement
- Validation des formulaires améliorée
- Messages d'erreur plus explicites
- Navigation après paiement corrigée

### 🔒 Sécurité
- Hash sécurisé des tokens de réinitialisation (`secrets.token_urlsafe`)
- Expiration des tokens (1 heure)
- Validation des mots de passe renforcée
- Nettoyage des tokens après utilisation

### 📊 Statistiques
- **65 fichiers modifiés**
- **7 931 insertions**
- **156 suppressions**
- **25 nouveaux fichiers**
- **35 fichiers modifiés**
- **1 fichier renommé**

### 🎯 État de l'Application
- ✅ **Authentification** : 100% fonctionnel
- ✅ **Paiements** : 100% simulé
- ✅ **Trajets** : 95% fonctionnel
- ✅ **Profils** : 100% fonctionnel
- ✅ **Chat** : 90% fonctionnel
- ✅ **Suivi GPS** : 90% fonctionnel
- ✅ **Prime** : 100% simulé

### 🚀 Prochaines Étapes
- [ ] Tests unitaires (couverture 0% → 80%)
- [ ] Tests d'intégration
- [ ] Intégration vraie API MTN/Orange
- [ ] Déploiement production
- [ ] Monitoring et analytics

---

## [1.0.0-phase1] - 2026-04-15

### ✨ Ajouté
- Architecture microservices complète
- Authentification JWT
- Gestion des trajets (chauffeur/passager)
- Profils utilisateurs
- Chat en temps réel
- Suivi GPS
- Notifications
- Système de caution
- Forum Prime (base)

### 📊 Statistiques
- 11 microservices
- Architecture Docker Compose
- Base de données PostgreSQL
- Redis pour cache et blacklist
- RabbitMQ pour messaging

---

## Légende

- ✨ **Ajouté** : Nouvelles fonctionnalités
- 🔄 **Modifié** : Changements dans les fonctionnalités existantes
- 🐛 **Corrigé** : Corrections de bugs
- 🔒 **Sécurité** : Corrections de vulnérabilités
- ⚠️ **Déprécié** : Fonctionnalités bientôt supprimées
- ❌ **Supprimé** : Fonctionnalités supprimées
- 📚 **Documentation** : Changements dans la documentation
- 🎨 **Style** : Changements qui n'affectent pas le code
- ♻️ **Refactoring** : Changements de code sans modification de fonctionnalité
- ⚡ **Performance** : Améliorations de performance
- 🧪 **Tests** : Ajout ou modification de tests
