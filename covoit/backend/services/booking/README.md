# Booking Service - Service de Réservation COVOIT

## 📋 Vue d'ensemble

Le **Booking Service** gère toutes les réservations de trajets dans l'application COVOIT. C'est un microservice FastAPI indépendant qui offre une API REST complète pour:

- ✅ Créer des réservations de trajets
- ✅ Vérifier et rechercher les réservations
- ✅ Confirmer les réservations après paiement
- ✅ Gérer les annulations et les no-shows
- ✅ Communiquer entre conducteur et passager via des notes
- ✅ Fournir des statistiques de réservation

## 🏗️ Architecture

```
Booking Service (Port 8004)
│
├── PostgreSQL Database (Port 5432)
│   └── booking_db
│
├── Application FastAPI
│   ├── Core
│   │   └── Configuration
│   ├── Models (SQLAlchemy ORM)
│   │   ├── Booking
│   │   └── BookingNote
│   ├── Schemas (Pydantic Validation)
│   │   └── Requêtes/Réponses DTOs
│   ├── Services (Logique métier)
│   │   └── BookingService
│   └── Routes (API Endpoints)
│       ├── /bookings (CRUD)
│       └── /health
└── Docker & Infrastructure
    ├── Dockerfile
    ├── requirements.txt
    └── .env.example
```

## 🗄️ Schéma de Base de Données

### Table: bookings
```
id (UUID, PRIMARY KEY)
trip_id (UUID, INDEX)
passenger_id (UUID, INDEX)
number_of_seats (INTEGER)
total_price (FLOAT)
status (ENUM: pending, confirmed, cancelled, completed, no_show)
pickup_location (STRING, NULLABLE)
dropoff_location (STRING, NULLABLE)
payment_id (UUID, NULLABLE)
driver_notes (STRING, NULLABLE)
created_at (DATETIME)
updated_at (DATETIME)
```

### Table: booking_notes
```
id (UUID, PRIMARY KEY)
booking_id (UUID, FOREIGN KEY)
author_id (UUID)
text (STRING)
created_at (DATETIME)
```

## 📡 Endpoints API

### 1. Créer une Réservation
```http
POST /bookings
Content-Type: application/json

{
  "trip_id": "550e8400-e29b-41d4-a716-446655440000",
  "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
  "number_of_seats": 2,
  "total_price": 5000.0,
  "pickup_location": "3.848,11.502",
  "dropoff_location": "3.868,11.516"
}
```

### 2. Récupérer une Réservation
```http
GET /bookings/{booking_id}
```

### 3. Récupérer les Réservations d'un Passager
```http
GET /bookings/passenger/{passenger_id}?limit=20&offset=0
```

### 4. Récupérer les Réservations d'un Trajet
```http
GET /bookings/trip/{trip_id}?limit=50&offset=0
```

### 5. Rechercher avec Filtres
```http
POST /bookings/search
Content-Type: application/json

{
  "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "confirmed",
  "limit": 20,
  "offset": 0
}
```

### 6. Mettre à Jour une Réservation
```http
PUT /bookings/{booking_id}
Content-Type: application/json

{
  "status": "confirmed",
  "driver_notes": "Attendre à la gare"
}
```

### 7. Confirmer une Réservation
```http
POST /bookings/{booking_id}/confirm
Content-Type: application/json

{
  "payment_id": "550e8400-e29b-41d4-a716-446655440003"
}
```

### 8. Annuler une Réservation
```http
POST /bookings/{booking_id}/cancel
Content-Type: application/json

{
  "reason": "J'ai changé d'avis"
}
```

### 9. Marquer Comme Complété
```http
POST /bookings/{booking_id}/complete
```

### 10. Marquer Comme No-Show
```http
POST /bookings/{booking_id}/no-show
```

### 11. Ajouter une Note
```http
POST /bookings/{booking_id}/notes
Content-Type: application/json

{
  "author_id": "550e8400-e29b-41d4-a716-446655440001",
  "text": "Je serai 5 mins en retard"
}
```

### 12. Récupérer les Notes
```http
GET /bookings/{booking_id}/notes
```

### 13. Statistiques
```http
GET /bookings/stats/passenger/{passenger_id}
```

### 14. Health Check
```http
GET /health
```

## 🚀 Installation et Démarrage

### Installation Locale

```bash
# Naviguer vers le répertoire
cd backend/services/booking

# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
cp .env.example .env

# Lancer le service
uvicorn app.main:app --reload --port 8004
```

### Installation Docker

```bash
cd backend
docker-compose up booking-service postgres-booking
```

## 📦 Structure du Projet

```
booking/
├── app/
│   ├── main.py
│   ├── api/
│   │   └── routes/
│   │       ├── bookings.py
│   │       └── health.py
│   ├── core/
│   │   └── config.py
│   ├── db/
│   │   └── session.py
│   ├── models/
│   │   └── booking.py
│   ├── schemas/
│   │   └── booking.py
│   └── services/
│       └── booking_service.py
├── Dockerfile
├── requirements.txt
├── .env.example
└── README.md
```

## 🔄 Flux de Réservation

```
1. Passager crée une réservation
   POST /bookings → Status: PENDING

2. Passager effectue un paiement
   Payment Service → Status devient CONFIRMED

3. Conducteur vérifier les réservations
   GET /bookings/trip/{trip_id}

4. Conducteur dépone le passager
   POST /bookings/{id}/complete → Status: COMPLETED

5. (Alternative) Passager absent
   POST /bookings/{id}/no-show → Status: NO_SHOW
```

## 💬 Communication Conducteur-Passager

Les notes permettent l'échange d'informations:

```
- Passager: "Je serai en retard de 10 min"
  POST /bookings/{id}/notes

- Conducteur: "OK, je vous attendrai à l'entrée"
  POST /bookings/{id}/notes

- Voir l'historique:
  GET /bookings/{id}/notes
```

## 📊 Statuts de Réservation

| Statut | Signification | Actions Possibles |
|--------|---------------|-------------------|
| PENDING | En attente de paiement | Payer, Annuler |
| CONFIRMED | Confirmée et payée | Compléter, Annuler, No-show |
| CANCELLED | Annulée | Consulter |
| COMPLETED | Trajet terminé | Consulter, Noter |
| NO_SHOW | Passager absent | Consulter |

## 🔒 Sécurité

Variables d'environnement à configurer:
```env
SECRET_KEY=<clé aléatoire de 32+ caractères>
DATABASE_URL=postgresql://user:password@postgres-booking:5432/booking_db
```

## 🧪 Tests

```bash
pytest
pytest --cov=app
```

## 👤 Auteur

Service créé pour l'application COVOIT - Plateforme de covoiturage Camerounaise

## 📄 Licence

Propriétaire - COVOIT Inc.
