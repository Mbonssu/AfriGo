# Fix: Gestion des Places et Notifications

## Problème Actuel

Actuellement, le système a les composants suivants mais ils ne sont pas connectés correctement :

### 1. **Service de Trajet (Trip Service)** ✅
- Possède un champ `available_seats` dans la base de données
- A une fonction `book_seat()` qui :
  - Vérifie si assez de places disponibles
  - Décrémente `available_seats`
  - Retourne `False` si pas assez de places
- Endpoint: `POST /trips/{trip_id}/book?passenger_count=X`

### 2. **Service de Réservation (Booking Service)** ❌
- Crée des réservations SANS vérifier les places disponibles
- Ne communique PAS avec le Trip Service
- Permet donc de créer plus de réservations que de places disponibles

### 3. **Notifications** ❌
- Pas de système de notifications implémenté
- Le chauffeur n'est pas notifié quand un passager réserve
- Le passager n'est pas notifié quand le chauffeur accepte

## Solution Requise

### Phase 1: Intégration Réservation ↔ Trajet

#### A. Modifier le Booking Service pour appeler le Trip Service

**Fichier:** `covoit/backend/services/booking/app/services/booking_service.py`

```python
import httpx
from app.core.config import settings

@staticmethod
async def create_booking(db: Session, request: BookingCreateRequest) -> BookingResponse:
    """
    Crée une nouvelle réservation ET réserve les places dans le trajet.
    """
    
    # 1. Appeler le Trip Service pour réserver les places
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{settings.TRIP_SERVICE_URL}/trips/{request.trip_id}/book",
                params={"passenger_count": request.number_of_seats}
            )
            
            if response.status_code != 200:
                raise ValueError("Pas assez de places disponibles")
                
        except httpx.RequestError:
            raise ValueError("Impossible de contacter le service de trajets")
    
    # 2. Si réservation réussie, créer la réservation en base
    db_booking = Booking(
        trip_id=request.trip_id,
        passenger_id=request.passenger_id,
        number_of_seats=request.number_of_seats,
        total_price=request.total_price,
        pickup_location=request.pickup_location,
        dropoff_location=request.dropoff_location,
        status=BookingStatus.PENDING,
    )
    
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    
    return BookingResponse.model_validate(db_booking)
```

#### B. Gérer l'annulation de réservation

Quand une réservation est annulée, il faut **libérer les places** :

```python
@staticmethod
async def cancel_booking(db: Session, booking_id: UUID) -> BookingResponse:
    """
    Annule une réservation ET libère les places.
    """
    
    db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
    
    if db_booking is None:
        raise ValueError(f"Réservation {booking_id} non trouvée")
    
    if db_booking.status == BookingStatus.COMPLETED:
        raise ValueError("Impossible d'annuler un trajet déjà complété")
    
    # Libérer les places dans le Trip Service
    async with httpx.AsyncClient() as client:
        await client.post(
            f"{settings.TRIP_SERVICE_URL}/trips/{db_booking.trip_id}/release",
            params={"passenger_count": db_booking.number_of_seats}
        )
    
    db_booking.status = BookingStatus.CANCELLED
    db_booking.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(db_booking)
    
    return BookingResponse.model_validate(db_booking)
```

#### C. Ajouter endpoint pour libérer les places

**Fichier:** `covoit/backend/services/trip/app/services/trip_service.py`

```python
@staticmethod
def release_seats(db: Session, trip_id: UUID, passenger_count: int) -> bool:
    """
    Libère des places dans un trajet (après annulation).
    """
    logger.info(f"Libération {passenger_count} place(s) trajet {trip_id}")
    
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    
    if not trip:
        logger.warning(f"Trajet non trouvé: {trip_id}")
        raise ValueError(f"Trajet avec ID {trip_id} non trouvé")
    
    # Incrémenter les places disponibles
    trip.available_seats += passenger_count
    
    # Ne pas dépasser le total
    if trip.available_seats > trip.total_seats:
        trip.available_seats = trip.total_seats
    
    db.commit()
    
    logger.info(f"Places libérées, places disponibles: {trip.available_seats}")
    
    return True
```

### Phase 2: Système de Notifications

#### A. Service de Notifications (Nouveau)

Créer un nouveau microservice : `notification-service`

**Structure:**
```
backend/services/notification/
├── app/
│   ├── main.py
│   ├── models/
│   │   └── notification.py
│   ├── services/
│   │   └── notification_service.py
│   └── api/
│       └── routes/
│           └── notifications.py
├── Dockerfile
└── requirements.txt
```

**Modèle Notification:**
```python
class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    type = Column(String, nullable=False)  # 'booking_created', 'booking_accepted', etc.
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    data = Column(JSON, nullable=True)  # Données supplémentaires
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

#### B. Types de Notifications

1. **Pour le Chauffeur:**
   - `booking_created`: "Nouvelle réservation pour votre trajet Yaoundé → Douala"
   - `booking_cancelled`: "Un passager a annulé sa réservation"

2. **Pour le Passager:**
   - `booking_accepted`: "Votre réservation a été acceptée par le chauffeur"
   - `booking_rejected`: "Votre réservation a été refusée"
   - `trip_cancelled`: "Le trajet a été annulé par le chauffeur"
   - `trip_starting_soon`: "Votre trajet commence dans 1 heure"

#### C. Intégration avec les Services

**Dans Booking Service:**
```python
# Après création de réservation
await notification_service.send_notification(
    user_id=driver_id,
    type="booking_created",
    title="Nouvelle réservation",
    message=f"{passenger_name} a réservé {seats} place(s)",
    data={"booking_id": str(booking.id), "trip_id": str(trip_id)}
)

# Après acceptation
await notification_service.send_notification(
    user_id=passenger_id,
    type="booking_accepted",
    title="Réservation acceptée",
    message=f"Le chauffeur a accepté votre réservation",
    data={"booking_id": str(booking.id)}
)
```

#### D. Frontend (Flutter)

**Provider pour Notifications:**
```dart
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  // WebSocket ou polling pour les notifications en temps réel
  return notificationRepository.getNotificationsStream();
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
```

**Badge de Notifications:**
```dart
Badge(
  label: Text('${unreadCount}'),
  child: IconButton(
    icon: Icon(Icons.notifications),
    onPressed: () => Navigator.push(...),
  ),
)
```

## Ordre d'Implémentation

1. ✅ **Vérifier que `book_seat` fonctionne** (déjà implémenté)
2. ⏳ **Ajouter `release_seats` au Trip Service**
3. ⏳ **Modifier Booking Service pour appeler Trip Service**
4. ⏳ **Tester le flux complet de réservation**
5. ⏳ **Créer le Notification Service**
6. ⏳ **Intégrer les notifications dans Booking Service**
7. ⏳ **Ajouter l'UI des notifications dans Flutter**

## Tests à Effectuer

### Test 1: Limite de Places
1. Créer un trajet avec 2 places
2. Réserver 2 places → ✅ Succès
3. Essayer de réserver 1 place supplémentaire → ❌ Erreur "Pas assez de places"

### Test 2: Annulation
1. Créer un trajet avec 2 places
2. Réserver 2 places (0 places restantes)
3. Annuler 1 réservation (1 place libérée)
4. Réserver 1 place → ✅ Succès

### Test 3: Notifications
1. Passager réserve → Chauffeur reçoit notification
2. Chauffeur accepte → Passager reçoit notification
3. Chauffeur refuse → Passager reçoit notification

## Fichiers à Modifier

- [ ] `backend/services/trip/app/services/trip_service.py` - Ajouter `release_seats`
- [ ] `backend/services/trip/app/api/routes/trips.py` - Ajouter endpoint `/release`
- [ ] `backend/services/booking/app/services/booking_service.py` - Appeler Trip Service
- [ ] `backend/services/booking/app/core/config.py` - Ajouter `TRIP_SERVICE_URL`
- [ ] `backend/docker-compose.yml` - Ajouter notification-service
- [ ] `lib/data/repositories/booking_repository.dart` - Gérer erreurs de places
- [ ] `lib/screens/passenger/trip_detail_screen.dart` - Afficher erreur si plus de places
