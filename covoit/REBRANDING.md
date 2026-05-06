# Rebranding: 237COVOIT → AfriGo

## Changements effectués

### 1. Nom de l'application
- **Ancien**: 237COVOIT / Covoit
- **Nouveau**: AfriGo

### 2. Domaines et URLs
- **Ancien**: api.237covoit.cm, support@237covoit.cm
- **Nouveau**: api.afrigo.cm, support@afrigo.cm

### 3. Identifiants de package

#### Android
- **Ancien**: `com.example.covoit_237`
- **Nouveau**: `com.afrigo.app`
- Fichier MainActivity déplacé vers: `com/afrigo/app/MainActivity.kt`

#### iOS/macOS
- **Ancien**: `com.example.covoit237`
- **Nouveau**: `com.afrigo.app`

#### Windows
- **Ancien**: `covoit_237.exe`
- **Nouveau**: `afrigo.exe`

### 4. Fichiers modifiés

#### Frontend (Flutter)
- ✅ `lib/main.dart` - Titre de l'application
- ✅ `lib/core/constants/api_endpoints.dart` - URLs et commentaires
- ✅ `lib/screens/driver/driver_home.dart` - Nom dans l'interface
- ✅ `lib/screens/trip_tracking_screen.dart` - Support
- ✅ `lib/screens/profile_screen.dart` - À propos et FAQ
- ✅ `pubspec.yaml` - Description
- ✅ `android/app/src/main/AndroidManifest.xml` - Label
- ✅ `android/app/build.gradle.kts` - Package et applicationId
- ✅ `android/app/src/main/kotlin/` - Package restructuré
- ✅ `macos/Runner/Configs/AppInfo.xcconfig` - Nom et bundle ID
- ✅ `windows/CMakeLists.txt` - Nom binaire
- ✅ `windows/runner/main.cpp` - Titre fenêtre
- ✅ `windows/runner/Runner.rc` - Métadonnées
- ✅ `web/manifest.json` - Nom web app
- ✅ `test/widget_test.dart` - Tests

#### Backend
- ✅ `backend/api-gateway/app/core/config.py` - APP_NAME
- ✅ `backend/api-gateway/app/main.py` - Titre API
- ✅ `backend/services/auth/app/core/config.py` - APP_NAME
- ✅ `backend/services/auth/app/main.py` - Description

### 5. Actions requises après le rebranding

#### Développement
1. Nettoyer le build Flutter:
   ```bash
   cd covoit
   flutter clean
   flutter pub get
   ```

2. Rebuild l'application:
   ```bash
   flutter run
   ```

#### Production
1. Mettre à jour les variables d'environnement:
   - `API_BASE_URL` → `https://api.afrigo.cm`
   
2. Configurer le DNS:
   - `api.afrigo.cm` → Serveur backend
   
3. Mettre à jour les certificats SSL pour le nouveau domaine

4. Mettre à jour les stores:
   - Google Play Store: Nouveau package `com.afrigo.app`
   - Apple App Store: Nouveau bundle ID `com.afrigo.app`

5. Mettre à jour les services tiers:
   - Firebase (si utilisé)
   - Services de paiement (MTN, Orange Money)
   - Services d'email
   - Analytics

### 6. Branding visuel (à faire)
- [ ] Logo AfriGo
- [ ] Icône de l'application
- [ ] Splash screen
- [ ] Couleurs de marque (actuellement: vert #1D9E75)
- [ ] Assets marketing

### 7. Communication
- [ ] Annoncer le changement de nom aux utilisateurs
- [ ] Mettre à jour les réseaux sociaux
- [ ] Mettre à jour le site web
- [ ] Mettre à jour la documentation

## Notes importantes

- Le package name `covoit_237` dans `pubspec.yaml` reste inchangé pour éviter les conflits de dépendances
- Les noms de classes Dart (`CovoitApp`) peuvent rester inchangés (usage interne)
- Les URLs de développement utilisent toujours `192.168.45.54:8000`
- La migration est rétrocompatible avec les données existantes

## Date de rebranding
6 mai 2026
