# 🐛 Corrections de bugs - Session du 6 mai 2026

## ✅ Bugs corrigés

### 1. Validation de date/heure trop restrictive (Publication de trajet)
**Problème :** L'application rejetait les trajets avec une heure en dehors de 5h-22h, même pour des dates futures.

**Solution :**
- Supprimé la validation restrictive de l'heure (5h-22h)
- Conservé la validation des 30 minutes minimum à l'avance
- Ajouté une validation pour éviter les dates trop lointaines (90 jours max)

**Fichier modifié :** `lib/screens/driver/post_trip_screen.dart`

**Résultat :** Les trajets peuvent maintenant être publiés à n'importe quelle heure (00h-23h59), pourvu que le départ soit au moins 30 minutes dans le futur.

---

### 2. Erreur backend lors de la création des waypoints
**Problème :** Le backend essayait de convertir les waypoints en DTO avant que les champs `id` et `created_at` soient générés par la base de données.

**Erreur :**
```
2 validation errors for WaypointResponse
id: UUID input should be a string, bytes or UUID object
created_at: Input should be a valid datetime
```

**Solution :**
- Ajouté un `db.flush()` après la création des waypoints
- Conversion en `WaypointResponse` après le flush pour avoir tous les champs remplis

**Fichier modifié :** `backend/services/trip/app/services/trip_service.py`

**Résultat :** Les trajets avec points de ramassage (waypoints) se créent maintenant sans erreur.

---

### 3. Rafraîchissement de l'écran d'accueil après publication
**Problème :** Après avoir publié un trajet, il n'apparaissait pas sur l'écran d'accueil du chauffeur.

**Cause :** L'écran d'accueil utilise `driverTripsByIdProvider` pour charger les trajets, mais seul `driverTripsProvider` était invalidé après la publication.

**Solution :** Invalider les deux providers après la publication d'un trajet.

**Fichier modifié :** `lib/screens/driver/post_trip_screen.dart`

**Résultat :** Les trajets publiés apparaissent maintenant immédiatement sur l'écran d'accueil.

---

### 4. Erreur de compilation - Widget _QuickAction
**Problème :** Le widget `_QuickAction` nécessitait un paramètre `label` obligatoire, causant une erreur de compilation.

**Solution :**
- Rendu le paramètre `label` optionnel
- Si `label` est fourni → affiche icône + texte
- Si `label` est `null` → affiche uniquement l'icône centrée (design épuré)

**Fichier modifié :** `lib/screens/driver/driver_home.dart`

**Résultat :** Design plus épuré avec uniquement les icônes pour les actions rapides.

---

## ⚠️ Limitations connues (non critiques)

### 1. Service de paiement désactivé
**Statut :** Le service payment est commenté dans `docker-compose.yml`

**Impact :** Les tentatives de paiement (abonnement Prime, etc.) retournent une erreur 503.

**Solution temporaire :** Le service doit être implémenté et activé dans docker-compose.

**Logs :**
```
POST http://192.168.45.54:8000/api/payments/initiate
Erreur serveur (503). Réessayez plus tard.
```

---

### 2. WebSocket notifications non implémenté
**Statut :** Le service notification n'a pas de support WebSocket.

**Impact :** Les notifications en temps réel ne fonctionnent pas. L'application tente de se reconnecter en boucle.

**Solution temporaire :** Les notifications fonctionnent en HTTP (polling). Le WebSocket peut être implémenté plus tard pour les notifications en temps réel.

**Logs :**
```
[WS] Connecté à ws://192.168.45.54:8000/ws/notifications?token=...
[WS] Connexion fermée
[WS] Tentative de reconnexion...
```

---

## 📊 Résumé

| Bug | Statut | Priorité | Impact |
|-----|--------|----------|--------|
| Validation date/heure restrictive | ✅ Corrigé | Haute | Bloquant |
| Erreur création waypoints | ✅ Corrigé | Haute | Bloquant |
| Rafraîchissement écran d'accueil | ✅ Corrigé | Moyenne | UX |
| Erreur compilation _QuickAction | ✅ Corrigé | Haute | Bloquant |
| Service payment désactivé | ⚠️ Connu | Basse | Fonctionnalité future |
| WebSocket notifications | ⚠️ Connu | Basse | Amélioration future |

---

## 🚀 Prochaines étapes recommandées

1. **Implémenter le service de paiement**
   - Activer le service dans docker-compose
   - Intégrer MTN Mobile Money / Orange Money
   - Tester les flux de paiement

2. **Implémenter WebSocket pour notifications**
   - Ajouter les routes WebSocket dans le service notification
   - Gérer les connexions persistantes
   - Envoyer les notifications en temps réel

3. **Tests end-to-end**
   - Tester le flux complet de publication de trajet
   - Tester les réservations avec waypoints
   - Vérifier l'affichage des trajets sur tous les écrans

---

**Date :** 6 mai 2026  
**Version :** AfriGo v1.0.0  
**Commits :**
- `47eb5bc` - fix: Correction bugs publication de trajet
- `dbd0ed8` - fix: Rafraîchir l'écran d'accueil après publication de trajet
- `835c55c` - fix: Rendre le label optionnel dans _QuickAction
