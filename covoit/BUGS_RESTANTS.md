# 🐛 Bugs Restants - AfriGo

## Date: 6 Mai 2026

### ✅ Bugs Corrigés Aujourd'hui

1. **✅ Validation date/heure publication trajet**
   - Suppression restriction 5h-22h
   - Seule contrainte: 30 minutes minimum à l'avance
   
2. **✅ Erreur création waypoints**
   - Ajout flush avant conversion en DTO
   - Champs id et created_at maintenant remplis

3. **✅ Rafraîchissement écran d'accueil chauffeur**
   - Invalidation de driverTripsByIdProvider après publication
   
4. **✅ Label optionnel dans _QuickAction**
   - Design plus épuré avec icônes seules

---

## ❌ Bugs À Corriger

### 1. Service de Paiement Indisponible (503)
**Priorité:** 🔴 HAUTE

**Problème:**
- Le service payment n'est pas démarré dans docker-compose
- Toutes les tentatives de paiement échouent avec erreur 503

**Solution:**
- Décommenter le service payment dans docker-compose.yml
- OU implémenter la simulation de paiement côté frontend
- OU créer un service payment mock

**Fichiers concernés:**
- `covoit/backend/docker-compose.yml` (ligne ~200)
- `covoit/lib/screens/payment/` (écrans de simulation)

---

### 2. Avis Mockés sur Profil Chauffeur
**Priorité:** 🟡 MOYENNE

**Problème:**
- Les avis affichés sont hardcodés (Aissatou B., Michel T., Caroline N.)
- Ne correspondent pas aux vraies données de la base

**Solution:**
- Créer un endpoint backend pour récupérer les avis d'un chauffeur
- Remplacer les avis mockés par un appel API
- Afficher "Aucun avis" si pas d'avis réels

**Fichiers concernés:**
- `covoit/lib/screens/driver/driver_profile_screen.dart` (lignes 302-323)
- Backend: créer route GET `/api/users/profile/{id}/reviews`

**Code à remplacer:**
```dart
// Lignes 302-323 dans driver_profile_screen.dart
const _ReviewTile(
  name: 'Aissatou B.',
  rating: 5,
  comment: 'Chauffeur très sympathique, conduite douce et ponctuel !',
  date: '20 Mars',
),
```

---

### 3. Trajets Disponibles Non Affichés (Passager)
**Priorité:** 🔴 HAUTE

**Problème:**
- Section "Prochains voyages disponibles" ne charge pas les trajets
- Erreur 405 "Method Not Allowed" sur GET `/api/trips`

**Cause:**
- La route GET `/api/trips` avec paramètres n'existe pas
- Le gateway exige from_city et to_city pour `/search`

**Solution Tentée:**
- Créé `allActiveTripsProvider` qui appelle `/search` avec paramètres vides
- Mais le gateway exige from_city et to_city (Query(..., required))

**Solution À Implémenter:**
1. **Option A:** Modifier le gateway pour rendre from_city et to_city optionnels
   ```python
   # Dans covoit/backend/api-gateway/app/api/routes/trips.py ligne 82
   from_city: str = Query(None, description="Ville de départ (optionnel)"),
   to_city: str = Query(None, description="Ville d'arrivée (optionnel)"),
   ```

2. **Option B:** Créer une nouvelle route GET `/api/trips/active` dans le backend
   ```python
   @router.get("/active")
   async def get_active_trips(limit: int = 20):
       # Retourner tous les trajets actifs
   ```

**Fichiers concernés:**
- `covoit/backend/api-gateway/app/api/routes/trips.py` (ligne 82-84)
- `covoit/backend/services/trip/app/api/routes/trips.py`
- `covoit/lib/data/repositories/journey_repository.dart`

---

### 4. Routes Populaires en Cache
**Priorité:** 🟢 BASSE

**Problème:**
- Les routes populaires sont mises en cache
- Ne se mettent pas à jour après publication d'un nouveau trajet

**Solution:**
- Invalider `popularRoutesProvider` après publication (✅ FAIT)
- Vérifier que le backend recalcule bien les stats

**Fichiers concernés:**
- `covoit/lib/screens/driver/post_trip_screen.dart` (✅ déjà corrigé)
- Backend: vérifier la requête SQL dans `/popular`

---

## 📝 Notes Techniques

### Architecture Microservices
- **Gateway:** `http://192.168.45.54:8000`
- **Services internes:** auth:8001, user:8002, trip:8003, booking:8004, etc.
- **Flutter** ne parle QU'AU GATEWAY

### Providers Riverpod
- `allActiveTripsProvider` - Tous les trajets actifs
- `driverTripsProvider` - Trajets du chauffeur connecté
- `driverTripsByIdProvider` - Trajets d'un chauffeur spécifique
- `popularRoutesProvider` - Routes populaires
- `searchTripsProvider` - Recherche avec filtres

### Routes Backend Trip Service
- `POST /trips/` - Créer un trajet ✅
- `GET /trips/search` - Rechercher (from_city et to_city REQUIS) ⚠️
- `GET /trips/{id}` - Détails d'un trajet ✅
- `GET /trips/driver/{id}` - Trajets d'un chauffeur ✅
- `GET /trips/popular` - Routes populaires ✅

---

## 🎯 Prochaines Étapes

1. **Corriger le chargement des trajets disponibles** (Priorité 1)
   - Rendre from_city et to_city optionnels dans le gateway
   - Tester avec `flutter run`

2. **Implémenter simulation de paiement** (Priorité 1)
   - Suivre `PAYMENT_SIMULATION.md`
   - Créer écrans de simulation

3. **Remplacer avis mockés** (Priorité 2)
   - Créer endpoint backend pour les avis
   - Intégrer dans driver_profile_screen.dart

4. **Tester mode Prime** (Priorité 2)
   - Activer Prime dans la BD avec script SQL
   - Vérifier badge, forum, priorité

---

## 🔧 Commandes Utiles

```bash
# Démarrer les services
cd covoit/backend
docker compose up -d

# Voir les logs
docker logs covoit-trip --tail 50
docker logs covoit-gateway --tail 50

# Redémarrer un service
docker compose restart trip-service

# Activer Prime pour un utilisateur
cd scripts
./activate-prime.sh USER_ID
```

---

## 📞 Contact

Pour toute question, consulter :
- `PHOTO_MANAGEMENT_STATUS.md` - État gestion photos
- `PAYMENT_SIMULATION.md` - Simulation paiements
- `TEST_API.md` - Tests API backend
