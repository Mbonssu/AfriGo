# Fix: Statuts de Voyage et Notifications

## Problème 1: Logique des Statuts de Voyage

### Statuts Actuels
Les trajets ont ces statuts dans la base de données :
- `active` - Trajet publié, en attente de départ
- `ongoing` / `in_progress` - Trajet en cours
- `completed` - Trajet terminé
- `cancelled` - Trajet annulé

### Problème
Les trajets restent en statut `active` et ne passent jamais automatiquement en `ongoing` ou `completed`.

### Solution

#### Option 1: Transition Manuelle (Actuelle)
Le chauffeur clique sur "Démarrer" pour passer de `active` → `ongoing`
Le chauffeur clique sur "Terminer" pour passer de `ongoing` → `completed`

**Problème:** Le bouton "Terminer" n'existe pas !

#### Option 2: Transition Automatique (Recommandée)
- **À venir (active):** `departure_time` est dans le futur
- **En cours (ongoing):** `departure_time` est passé ET statut = `active`
- **Terminé (completed):** Trajet marqué manuellement comme terminé

### Implémentation Recommandée

#### A. Filtrage Côté Frontend (Solution Rapide)

**Fichier:** `lib/screens/driver/driver_trips_screen.dart`

```dart
data: (allTrips) {
  final now = DateTime.now();
  
  // À venir: statut active ET départ dans le futur
  final active = allTrips
      .where((t) => 
          t.status == 'active' && 
          t.departureTime.isAfter(now))
      .toList();
  
  // En cours: statut active ET départ passé, OU statut ongoing
  final ongoing = allTrips
      .where((t) => 
          (t.status == 'active' && t.departureTime.isBefore(now)) ||
          t.status == 'ongoing' || 
          t.status == 'in_progress')
      .toList();
  
  // Historique: completed ou cancelled
  final history = allTrips
      .where((t) => 
          t.status == 'completed' || 
          t.status == 'cancelled')
      .toList();

  return TabBarView(...);
}
```

#### B. Ajouter Bouton "Terminer le Trajet"

Dans `_DriverTripCard`, ajouter pour les trajets `ongoing` :

```dart
else if (trip.status == 'ongoing' || trip.status == 'in_progress')
  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(...),
          icon: const Icon(Icons.people_rounded, size: 15),
          label: const Text('Passagers'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _completeTrip(context, ref, trip),
          icon: const Icon(Icons.check_circle_rounded, size: 15),
          label: const Text('Terminer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
          ),
        ),
      ),
    ],
  ),
```

#### C. Fonction pour Terminer un Trajet

```dart
Future<void> _completeTrip(BuildContext context, WidgetRef ref, AppTrip trip) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Terminer le trajet ?'),
      content: Text('Marquer le trajet ${trip.from} → ${trip.to} comme terminé ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Terminer'),
        ),
      ],
    ),
  );
  
  if (confirm != true || !context.mounted) return;
  
  try {
    await ref.read(journeyRepositoryProvider).completeTrip(trip.id);
    ref.invalidate(driverTripsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trajet terminé avec succès !'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }
}
```

#### D. Ajouter Endpoint Backend

**Fichier:** `backend/services/trip/app/api/routes/trips.py`

```python
@router.post(
    "/{trip_id}/complete",
    status_code=status.HTTP_200_OK,
    summary="Marquer un trajet comme terminé",
)
async def complete_trip(trip_id: UUID, db: Session = Depends(get_db)):
    """
    Marque un trajet comme terminé (completed).
    """
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        
        if not trip:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trajet non trouvé"
            )
        
        trip.status = TripStatus.COMPLETED
        trip.updated_at = datetime.utcnow()
        
        db.commit()
        
        return {"success": True, "message": "Trajet terminé"}
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
```

---

## Problème 2: Système de Notifications

### Notifications Manquantes

1. **Chauffeur reçoit notification quand:**
   - Un passager réserve son trajet
   - Un passager annule sa réservation

2. **Passager reçoit notification quand:**
   - Le chauffeur accepte sa réservation
   - Le chauffeur refuse sa réservation
   - Le trajet est annulé par le chauffeur
   - Le trajet commence bientôt (1h avant)

### Solution: Système de Notifications Simple

#### Architecture

```
┌─────────────────┐
│  Booking/Trip   │
│    Service      │
└────────┬────────┘
         │
         │ HTTP POST
         ▼
┌─────────────────┐
│  Notification   │
│    Service      │
└────────┬────────┘
         │
         │ Store in DB
         ▼
┌─────────────────┐
│   PostgreSQL    │
│  notifications  │
└─────────────────┘
         │
         │ Polling/WebSocket
         ▼
┌─────────────────┐
│  Flutter App    │
└─────────────────┘
```

#### Implémentation Simplifiée (Sans Microservice)

**Option 1: Stocker dans User Service**

Ajouter table `notifications` dans user-service :

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);
```

**Option 2: Notifications In-App Simples (Solution Rapide)**

Pour l'instant, utiliser des **badges et indicateurs visuels** :

1. **Badge sur l'onglet "Passagers"** quand il y a des réservations en attente
2. **Badge sur "Mes Trajets"** quand une réservation est acceptée/refusée
3. **Polling toutes les 30 secondes** pour vérifier les nouvelles réservations

#### Implémentation Rapide (Flutter)

**Fichier:** `lib/data/providers/notification_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Compte les réservations en attente pour un chauffeur
final pendingBookingsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return 0;
  
  final trips = await ref.watch(driverTripsProvider.future);
  int count = 0;
  
  for (final trip in trips) {
    if (trip.status == 'active') {
      final bookings = await ref.read(tripBookingsProvider(trip.id).future);
      count += bookings.where((b) => b.status == 'pending').length;
    }
  }
  
  return count;
});

// Compte les notifications non lues pour un passager
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return 0;
  
  final bookings = await ref.watch(passengerTripsProvider.future);
  
  // Compter les réservations récemment acceptées/refusées
  return bookings
      .where((b) => 
          (b.status == 'accepted' || b.status == 'rejected') &&
          b.updatedAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
      .length;
});
```

**Affichage du Badge:**

```dart
// Dans driver_home.dart
Badge(
  label: Text('$pendingCount'),
  isLabelVisible: pendingCount > 0,
  child: IconButton(
    icon: Icon(Icons.people),
    onPressed: () => Navigator.push(...),
  ),
)
```

---

## Ordre d'Implémentation

### Phase 1: Statuts de Voyage (Urgent)
1. ✅ Modifier filtrage dans `driver_trips_screen.dart` (basé sur `departureTime`)
2. ✅ Ajouter bouton "Terminer" pour trajets en cours
3. ✅ Ajouter fonction `completeTrip` dans repository
4. ✅ Ajouter endpoint `/trips/{id}/complete` dans backend

### Phase 2: Notifications Basiques (Moyen Terme)
1. ⏳ Ajouter badges pour réservations en attente
2. ⏳ Ajouter indicateurs visuels pour réservations acceptées/refusées
3. ⏳ Implémenter polling toutes les 30s

### Phase 3: Système de Notifications Complet (Long Terme)
1. ⏳ Créer table `notifications` dans user-service
2. ⏳ Créer endpoints pour créer/lire/marquer notifications
3. ⏳ Intégrer appels de notification dans booking/trip services
4. ⏳ Implémenter WebSocket pour notifications temps réel
5. ⏳ Ajouter écran "Notifications" dans l'app

---

## Fichiers à Modifier

### Phase 1 (Statuts)
- [ ] `lib/screens/driver/driver_trips_screen.dart` - Filtrage intelligent
- [ ] `lib/data/repositories/journey_repository.dart` - Ajouter `completeTrip()`
- [ ] `lib/core/constants/api_endpoints.dart` - Ajouter endpoint
- [ ] `backend/services/trip/app/api/routes/trips.py` - Endpoint complete
- [ ] `backend/api-gateway/app/api/routes/trips.py` - Proxy endpoint

### Phase 2 (Badges)
- [ ] `lib/data/providers/notification_providers.dart` - Créer providers
- [ ] `lib/screens/driver/driver_home.dart` - Ajouter badge
- [ ] `lib/screens/passenger/passenger_home.dart` - Ajouter badge

### Phase 3 (Notifications Complètes)
- [ ] `backend/services/user/app/models/notification.py` - Modèle
- [ ] `backend/services/user/app/api/routes/notifications.py` - Endpoints
- [ ] `backend/services/booking/app/services/booking_service.py` - Envoyer notifications
- [ ] `lib/screens/notifications_screen.dart` - UI notifications
