# Trip Service

Service de gestion des trajets pour l'application 237COVOIT.

## Description

Le Trip Service est responsable de :

- **Création de trajets** : Les chauffeurs publient leurs trajets avec tous les détails (ville, heure, places, prix, etc)
- **Recherche de trajets** : Les passagers cherchent les trajets selon des critères (ville, date, places disponibles)
- **Gestion des trajets** : Modification et annulation des trajets
- **Disponibilité des places** : Gestion du nombre de places disponibles pour les réservations

## Architecture

```text
app/
├── main.py                 # Application FastAPI principale
├── core/
│   └── config.py          # Configuration (variables d'environnement)
├── models/
│   └── trip.py            # Modèles SQLAlchemy (Trip, Waypoint, TripConfort)
├── schemas/
│   └── trip.py            # DTOs Pydantic (validation requêtes/réponses)
├── services/
│   └── trip_service.py    # Logique métier (CRUD, recherche, etc)
├── api/
│   └── routes/
│       ├── trips.py       # Endpoints des trajets
│       └── health.py      # Endpoint de santé
└── db/
    └── session.py         # Configuration SQLAlchemy et session DB
```

## Base de Données

### Connexion

- **Type** : PostgreSQL
- **Host** : postgres-trip (Docker) ou localhost (dev local)
- **Port** : 5434
- **Database** : trip_db
- **User** : postgres
- **Password** : postgres

### Tables

- **trips** : Trajets principaux
- **waypoints** : Étapes intermédiaires des trajets
- **trip_comforts** : Options de confort disponibles dans les trajets

## Endpoints API

### Base URL

```text
http://localhost:8003
```

### Trajets

#### Créer un trajet

```json
POST /trips
Content-Type: application/json

{
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "departure_time": "2026-04-05T14:30:00",
  "total_seats": 4,
  "price_per_seat": 5000.0,
  "vehicle_model": "Toyota Fortuner 2020",
  "vehicle_plate": "CC1234",
  "is_prime": false,
  "waypoints": [
    {
      "city_name": "Nkongsamba",
      "order_index": 1,
      "estimated_time": "2026-04-05T16:00:00"
    }
  ],
  "comfort_options": ["ac", "wifi"]
}
```

Response (201):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": "driver-uuid",
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "departure_time": "2026-04-05T14:30:00",
  "total_seats": 4,
  "available_seats": 4,
  "price_per_seat": 5000.0,
  "vehicle_model": "Toyota Fortuner 2020",
  "vehicle_plate": "CC1234",
  "status": "active",
  "is_prime": false,
  "created_at": "2026-04-02T10:00:00",
  "updated_at": "2026-04-02T10:00:00",
  "waypoints": [],
  "comfort_options": ["ac", "wifi"]
}
```

#### Récupérer un trajet

```text
GET /trips/{trip_id}
```

Response (200):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": "driver-uuid",
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "departure_time": "2026-04-05T14:30:00",
  "total_seats": 4,
  "available_seats": 4,
  "price_per_seat": 5000.0,
  "vehicle_model": "Toyota Fortuner 2020",
  "vehicle_plate": "CC1234",
  "status": "active",
  "is_prime": false,
  "created_at": "2026-04-02T10:00:00",
  "updated_at": "2026-04-02T10:00:00",
  "waypoints": [],
  "comfort_options": ["ac", "wifi"]
}
```

#### Rechercher des trajets

```text
GET /trips/search?from_city=Douala&to_city=Yaoundé&departure_date=2026-04-05&passenger_count=2&sort_by=price
```

Response (200):

```json
{
  "total_results": 5,
  "trips": [],
  "filters_applied": {
    "from_city": "Douala",
    "to_city": "Yaoundé",
    "departure_date": "2026-04-05",
    "passenger_count": 2,
    "sort_by": "price"
  }
}
```

#### Modifier un trajet

```json
PATCH /trips/{trip_id}
Content-Type: application/json

{
  "price_per_seat": 4500.0,
  "status": "ongoing"
}
```

Response (200):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": "driver-uuid",
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "departure_time": "2026-04-05T14:30:00",
  "total_seats": 4,
  "available_seats": 4,
  "price_per_seat": 4500.0,
  "vehicle_model": "Toyota Fortuner 2020",
  "vehicle_plate": "CC1234",
  "status": "ongoing",
  "is_prime": false,
  "created_at": "2026-04-02T10:00:00",
  "updated_at": "2026-04-02T10:30:00",
  "waypoints": [],
  "comfort_options": ["ac", "wifi"]
}
```

#### Supprimer/Annuler un trajet

```text
DELETE /trips/{trip_id}
```

Response (204): No Content

#### Réserver des places

```text
POST /trips/{trip_id}/book?passenger_count=2
```

Response (200):

```json
{
  "success": true,
  "message": "2 place(s) réservée(s) avec succès",
  "trip_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Santé

#### Vérifier l'état du service

```text
GET /health
```

Response (200):

```json
{
  "status": "healthy",
  "service": "Trip Service",
  "version": "1.0.0"
}
```

## Installation Locale

### Prérequis

- Python 3.11+
- PostgreSQL 15+
- pip (gestionnaire de paquets Python)

### Étapes

1. **Cloner le repository**

```bash
cd /path/to/covoit/backend/services/trip
```

1. **Créer un environnement virtuel**

```bash
python3 -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

1. **Installer les dépendances**

```bash
pip install -r ../../requirements.txt
```

1. **Configurer l'environnement**

```bash
cp .env.example .env
# Éditer .env avec vos paramètres
```

1. **Créer la base de données**

```bash
# Créer manuellement la base "trip_db" dans PostgreSQL
psql -U postgres
CREATE DATABASE trip_db;
```

1. **Démarrer le service**

```bash
cd ../..  # Retourner au dossier backend
uvicorn services/trip/app/main:app --host 0.0.0.0 --port 8003 --reload
```

1. **Accéder à la documentation**

- Swagger UI: [http://localhost:8003/docs](http://localhost:8003/docs)
- ReDoc: [http://localhost:8003/redoc](http://localhost:8003/redoc)

## Déploiement Docker

### Avec docker-compose

```bash
cd backend
docker-compose up trip-service
```

### Avec Docker seul

```bash
docker build -f services/trip/Dockerfile -t trip-service:latest .
docker run -p 8003:8003 -e DATABASE_URL="..." trip-service:latest
```

## Variables d'Environnement

| Variable | Défaut | Description |
| -------- | ------ | ----------- |
| `DEBUG` | False | Mode debug (affiche requêtes SQL) |
| `DATABASE_URL` | postgresql://postgres:postgres@localhost:5434/trip_db | URL de connexion PostgreSQL |
| `SECRET_KEY` | your-secret-key... | Clé secrète pour JWT |

## Tests

### Lancer les tests (sera implémenté dans Phase 9)

```bash
pytest services/trip/tests/ -v
```

## Architecture Détaillée

### Flow de Création de Trajet

```text
POST /trips
    ↓
  routes/trips.py::create_trip()
    ↓
  services/trip_service.py::TripService.create_trip()
    ↓
  models/trip.py::Trip (SQLAlchemy insert)
    ↓
  PostgreSQL trip_db
    ↓
  Response TripResponse (DTO)
```

### Flow de Recherche de Trajet

```text
GET /trips/search?from_city=X&to_city=Y&date=Z
    ↓
  routes/trips.py::search_trips()
    ↓
  services/trip_service.py::TripService.search_trips()
    ↓
  Query DB: SELECT * FROM trips WHERE departure_city=X AND arrival_city=Y AND ...
    ↓
  Filter, Sort, Paginate
    ↓
  Response TripSearchResponse (liste de TripResponse)
```

## Intégration avec Autres Services

### API Gateway

L'API Gateway forward les requêtes `/api/trips/*` vers ce service:

```text
GET /api/trips → GET http://trip-service:8003/trips
POST /api/trips → POST http://trip-service:8003/trips
```

### Événements RabbitMQ (Futur)

Ce service publiera des événements:

- `trip.created` : Nouveau trajet créé
- `trip.updated` : Trajet modifié
- `trip.cancelled` : Trajet annulé
- `trip.completed` : Trajet terminé

Ces événements seront consommés par:

- Chat Service (pour créer conversations)
- Notification Service (notifier les passagers)
- Stats Service (mettre à jour statistiques chauffeur)

## Limitations Connues (À Implémenter)

- [ ] Pas de pagination sur /trips/search
- [ ] Pas de validations date (date passée refusée)
- [ ] Pas d'authentification JWT (driver_id forcé à "test")
- [ ] Pas de RabbitMQ events
- [ ] Pas d'upload d'images de véhicule
- [ ] Pas de géolocalisation (utilise villes seulement)
- [ ] Pas de cache Redis

## Contacts

Pour des questions sur ce service, contacter l'équipe backend.

---

**Version**: 1.0.0  
**Dernière mise à jour**: 2 Avril 2026
