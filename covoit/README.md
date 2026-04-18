# 237COVOIT — Flutter Frontend

Application de covoiturage intercités au Cameroun. Semblable à BlaBlaCar, adaptée au contexte local : Mobile Money, Orange Money, sécurité renforcée, chauffeurs Prime.

---

## Structure du projet

```
lib/
├── main.dart                          # Point d'entrée + gestion ThemeMode
├── app_theme.dart                     # Thèmes clair / sombre + AppColors
│
├── screens/
│   ├── splash_screen.dart             # Splash animé
│   ├── onboarding_screen.dart         # 3 slides d'intro + CTA inscription/connexion
│   ├── notifications_screen.dart      # Notifications push (passager + chauffeur)
│   ├── profile_screen.dart            # Profil + sélecteur de thème
│   │
│   ├── auth/
│   │   ├── login_screen.dart          # Connexion passager ou chauffeur
│   │   └── register_screen.dart       # Inscription 3 étapes (rôle → infos → docs)
│   │
│   ├── passenger/
│   │   ├── passenger_home.dart        # Accueil passager + BottomNav
│   │   ├── search_screen.dart         # Recherche avec autocomplétion des villes
│   │   ├── trip_detail_screen.dart    # Détail trajet + réservation + paiement
│   │   ├── my_trips_screen.dart       # Mes voyages (à venir / en cours / terminés)
│   │   ├── chat_screen.dart           # Chat passager ↔ chauffeur
│   │   └── rating_screen.dart         # Évaluation chauffeur (étoiles + tags + commentaire)
│   │
│   └── driver/
│       ├── driver_home.dart           # Accueil chauffeur + BottomNav
│       ├── post_trip_screen.dart      # Publication d'un trajet
│       ├── driver_trips_screen.dart   # Trajets actifs / en cours / historique
│       ├── driver_stats_screen.dart   # Statistiques + graphique revenus + avis
│       └── prime_forum_screen.dart    # Forum exclusif chauffeurs Prime
│
pubspec.yaml
```

---

## Fonctionnalités implémentées

### Modes de couleur ✅
- **Clair** (ThemeMode.light)
- **Sombre** (ThemeMode.dark) — toutes les surfaces, textes, cartes, inputs
- **Automatique** (ThemeMode.system) — suit le paramètre système
- Sélecteur dans **Profil → Apparence**, persisté via `CovoitApp.of(context).setThemeMode()`

### Passager ✅
- Inscription 3 étapes avec sélection de rôle
- Recherche de trajets avec **autocomplétion** des villes camerounaises
- Filtres (trier par heure / prix / note)
- Détail trajet avec profil chauffeur, badge Prime, étoiles
- **Réservation** avec sélection de places et paiement MTN / Orange Money
- Gestion des voyages (à venir, en cours, terminés)
- **Chat** temps réel avec le chauffeur
- **Évaluation** : étoiles + tags prédéfinis + commentaire libre

### Chauffeur Simple ✅
- Profil sans abonnement, non visible dans les recherches publiques
- Publication de trajet (route, date, heure, prix, nombre de places, préférences)
- **Caution 500 FCFA × nombre de places** affichée à la publication
- Gestion des passagers par trajet
- Statistiques (revenus, trajets, note, ponctualité)
- Notifications push

### Chauffeur Prime ✅
- Badge doré "PRIME" visible partout
- Apparaît en priorité dans les recherches
- **Forum exclusif Prime** : 3 onglets (Discussions / Annonces / Bons plans)
- Statistiques enrichies
- CTA d'upgrade pour les chauffeurs simples

### Sécurité & paiements ✅
- Caution **500 FCFA/réservation** pour les passagers
- Caution **500 FCFA/place** pour les chauffeurs simples
- Politique d'annulation affichée clairement
- Vérification CNI + permis + carte grise à l'inscription
- Paiement : **MTN Mobile Money** + **Orange Money**

---

## Installation

```bash
# Cloner le projet
git clone https://github.com/votre-org/237covoit.git
cd 237covoit

# Installer les dépendances
flutter pub get

# Télécharger la police Outfit depuis Google Fonts et placer dans :
# assets/fonts/Outfit-Regular.ttf
# assets/fonts/Outfit-Bold.ttf
# assets/fonts/Outfit-ExtraBold.ttf
# (ou utiliser google_fonts: GoogleFonts.outfit())

# Lancer en développement
flutter run

# Build Android
flutter build apk --release

# Build iOS
flutter build ipa --release
```

---

## Configuration Firebase (notifications push)

1. Créer un projet Firebase → `google-services.json` → `android/app/`
2. Pour iOS → `GoogleService-Info.plist` → `ios/Runner/`
3. Activer Firebase Cloud Messaging (FCM)

---

## Architecture recommandée

```
lib/
├── core/
│   ├── api/           # Dio + Retrofit pour l'API FastAPI
│   ├── models/        # User, Trip, Booking, Review, Message
│   ├── providers/     # AuthProvider, TripProvider, ChatProvider
│   └── services/      # NotificationService, LocationService, PaymentService
│
├── screens/           # (ci-dessus)
└── widgets/           # Composants réutilisables
```

---

## Palette de couleurs

| Nom | Hex | Usage |
|-----|-----|-------|
| Vert principal | `#1D9E75` | Marque, boutons, accents |
| Vert clair | `#E1F5EE` | Fonds, badges passif |
| Vert foncé | `#0F6E56` | AppBar dark gradient |
| Or Prime | `#EF9F27` | Badge Prime, étoiles |
| Or fond | `#FAEEDA` | Fond badge Prime |
| Corail | `#D85A30` | Alertes, annulation |
| Surface dark | `#1A1A18` | Cartes mode sombre |
| Fond dark | `#111110` | Scaffold mode sombre |

---

## Notes d'implémentation

- **Police** : `Outfit` (Google Fonts) — moderne, africaine-friendly, très lisible
- **Theme switching** : via `InheritedWidget` pattern (`CovoitApp.of(context)`)
- **Autocomplétion** : liste locale des villes du Cameroun (à connecter à l'API)
- **Chat** : UI complète, à connecter avec WebSocket (FastAPI + `web_socket_channel`)
- **Paiements** : UI complète, à intégrer avec l'API MTN MoMo et Orange Money
