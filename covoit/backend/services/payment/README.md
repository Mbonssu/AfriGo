# Payment Service - Service de Paiement COVOIT

## 📋 Vue d'ensemble

Le **Payment Service** gère tous les paiements de l'application COVOIT. C'est un microservice FastAPI indépendant qui offre une API REST complète pour:

- ✅ Créer des paiements MTN Mobile Money et Orange Money
- ✅ Vérifier le statut des paiements
- ✅ Rechercher l'historique des paiements
- ✅ Gérer les annulations et remboursements
- ✅ Fournir des statistiques de paiement

## 🏗️ Architecture

```
Payment Service (Port 8006)
│
├── PostgreSQL Database (Port 5435)
│   └── payment_db
│
├── Application FastAPI
│   ├── Core
│   │   └── Configuration (settings, variables d'environnement)
│   │
│   ├── Models (SQLAlchemy ORM)
│   │   ├── Payment (Table payments)
│   │   └── PaymentTransaction (Historique)
│   │
│   ├── Schemas (Pydantic Validation)
│   │   └── Requêtes/Réponses DTOs
│   │
│   ├── Services (Logique métier)
│   │   └── PaymentService (CRUD + business logic)
│   │
│   └── Routes (API Endpoints)
│       ├── /payments (CRUD payments)
│       └── /health (Health check)
│
└── Docker & Infrastructure
    ├── Dockerfile
    ├── docker-compose.yml
    └── requirements.txt
```

## 🗄️ Schéma de Base de Données

### Table: payments
```
id (UUID, PRIMARY KEY)
user_id (UUID, INDEX)
booking_id (UUID, INDEX, NULLABLE)
amount (FLOAT)
payment_method (ENUM: mtn, orange)
payment_type (ENUM: booking, caution, subscription)
phone_number (STRING)
status (ENUM: pending, success, failed, cancelled, refunded)
transaction_id (STRING, UNIQUE, NULLABLE)
created_at (DATETIME)
updated_at (DATETIME)
```

### Table: payment_transactions
Historique détaillé de chaque tentative de paiement:
```
id (UUID, PRIMARY KEY)
payment_id (UUID, FOREIGN KEY)
status (ENUM)
error_message (STRING, NULLABLE)
provider_response (STRING, NULLABLE)
created_at (DATETIME)
```

## 📡 Endpoints API

### 1. Créer un Paiement
```http
POST /payments
Content-Type: application/json

{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "booking_id": "550e8400-e29b-41d4-a716-446655440001",
  "amount": 5000.0,
  "payment_method": "mtn",
  "payment_type": "booking",
  "phone_number": "+237655123456"
}
```

**Réponse (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "amount": 5000.0,
  "status": "pending",
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:30:00"
}
```

### 2. Récupérer un Paiement
```http
GET /payments/{payment_id}
```

### 3. Récupérer les Paiements d'un Utilisateur
```http
GET /payments/user/{user_id}?limit=20&offset=0
```

### 4. Rechercher avec Filtres
```http
POST /payments/search
Content-Type: application/json

{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "payment_method": "mtn",
  "min_amount": 1000,
  "max_amount": 10000,
  "limit": 20,
  "offset": 0
}
```

### 5. Mettre à Jour le Statut
```http
PUT /payments/{payment_id}/status
Content-Type: application/json

{
  "status": "success",
  "transaction_id": "TXN123456789",
  "provider_response": "{...}"
}
```

### 6. Annuler un Paiement
```http
POST /payments/{payment_id}/cancel
```

### 7. Rembourser un Paiement
```http
POST /payments/{payment_id}/refund
Content-Type: application/json

{
  "reason": "Utilisateur a annulé sa réservation",
  "partial_amount": null
}
```

### 8. Obtenir les Statistiques
```http
GET /payments/stats/user/{user_id}
```

**Réponse:**
```json
{
  "total_amount": 50000.0,
  "total_count": 5,
  "success_count": 4,
  "failed_count": 1,
  "pending_count": 0,
  "cancelled_count": 0,
  "refunded_count": 0,
  "success_rate": 80.0,
  "average_amount": 10000.0
}
```

### 9. Health Check
```http
GET /health
```

**Réponse (200):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.123456",
  "service": "payment-service",
  "version": "1.0.0"
}
```

## 🚀 Installation et Démarrage

### Prérequis
- Python 3.11+
- PostgreSQL 14+
- Docker & Docker Compose (optionnel)

### Installation Locale

1. **Cloner/Naviguer vers le répertoire**
```bash
cd backend/services/payment
```

2. **Créer un environnement virtuel**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows
```

3. **Installer les dépendances**
```bash
pip install -r requirements.txt
```

4. **Configurer les variables d'environnement**
```bash
cp .env.example .env
# Éditer .env avec vos valeurs
```

5. **Lancer le service**
```bash
python -m app.main
# ou
uvicorn app.main:app --reload --port 8006
```

6. **Accéder à l'API**
- Swagger UI: http://localhost:8006/docs
- ReDoc: http://localhost:8006/redoc
- API: http://localhost:8006

## 🐳 Installation Docker

### Avec Docker Compose
```bash
cd backend
docker-compose up payment-service postgres-payment
```

### Build et Run Manuel
```bash
# Build l'image
docker build -t covoit/payment-service:1.0.0 services/payment/

# Créer le réseau Docker
docker network create covoit-network

# Lancer PostgreSQL
docker run -d \
  --name postgres-payment \
  --network covoit-network \
  -e POSTGRES_DB=payment_db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5435:5432 \
  postgres:14

# Lancer le service
docker run -d \
  --name payment-service \
  --network covoit-network \
  -e DATABASE_URL=postgresql://postgres:postgres@postgres-payment:5432/payment_db \
  -p 8006:8006 \
  covoit/payment-service:1.0.0
```

## 🧪 Tests

### Lancer les tests
```bash
pytest
```

### Coverage
```bash
pytest --cov=app
```

## 📦 Structure du Projet

```
payment/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app
│   ├── api/
│   │   ├── __init__.py
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── payments.py     # Endpoints CRUD
│   │       └── health.py       # Health check
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py           # Settings & env vars
│   ├── db/
│   │   ├── __init__.py
│   │   └── session.py          # SQLAlchemy setup
│   ├── models/
│   │   ├── __init__.py
│   │   └── payment.py          # ORM Models
│   ├── schemas/
│   │   ├── __init__.py
│   │   └── payment.py          # Pydantic DTOs
│   └── services/
│       ├── __init__.py
│       └── payment_service.py  # Business logic
├── Dockerfile
├── requirements.txt
├── .env.example
└── README.md
```

## 🔧 Dépendances Principales

| Package | Version | Utilisation |
|---------|---------|-------------|
| FastAPI | 0.104.1 | Framework web |
| Uvicorn | 0.24.0 | Serveur ASGI |
| SQLAlchemy | 2.0.23 | ORM |
| Pydantic | 2.5.0 | Validation |
| Psycopg2 | 2.9.9 | Driver PostgreSQL |

## 🔒 Sécurité

### Variables d'Environnement Sensibles
```env
SECRET_KEY=<clé aléatoire de 32+ caractères>
DATABASE_URL=postgresql://user:password@host:5435/payment_db
MTN_API_KEY=<clé API MTN>
ORANGE_API_KEY=<clé API Orange>
```

### CORS Configuration
Actuellement accepte les requêtes de:
- `http://localhost:3000` (frontend dev)
- `http://localhost:8000` (API Gateway)
- `http://api-gateway:8000` (Docker)

À restreindre en production!

## 📊 Flux de Paiement

```
1. Client crée un paiement
   POST /payments → Status: PENDING

2. API Gateway/Frontend appelle l'API MTN/Orange
   (Implémentation future)

3. Webhook du prestataire notifie le service
   PUT /payments/{id}/status → Status: SUCCESS/FAILED

4. Service met à jour le statut en base de données
   Event: payment_success / payment_failed

5. D'autres services sont notifiés
   (Booking Service met à jour la réservation)
```

## 🐛 Troubleshooting

### Erreur: "Could not connect to PostgreSQL"
```
Vérifier:
1. PostgreSQL est en cours d'exécution
2. Les paramètres DATABASE_URL sont corrects
3. La base de données 'payment_db' existe
```

### Erreur: "Port 8006 already in use"
```
Changer le port:
uvicorn app.main:app --port 8007
```

### Erreur: "Module not found"
```
S'assurer que les imports correspondent à la structure du projet:
from app.models.payment import Payment  # ✅ Correct
from models.payment import Payment      # ❌ Incorrect
```

## 📝 Statuts de Paiement

| Statut | Signification | Actions Possibles |
|--------|---------------|-------------------|
| PENDING | En attente de confirmation | Annuler |
| SUCCESS | Paiement réussi | Consulter, Rembourser |
| FAILED | Paiement échoué | Consulter, Relancer |
| CANCELLED | Paiement annulé | Consulter |
| REFUNDED | Remboursement lancé | Consulter |

## 🔄 Intégration avec d'autres Services

### API Gateway → Payment Service
```python
# api-gateway/app/api/routes/payments.py
@router.post("/payments")
async def create_payment(request: PaymentCreateRequest):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.PAYMENT_SERVICE_URL}/payments",
            json=request.dict()
        )
    return response.json()
```

### Booking Service → Payment Service
```python
# Vérifier un paiement avant de confirmer une réservation
response = requests.get(
    f"{PAYMENT_SERVICE_URL}/payments/{payment_id}"
)
if response.json()["status"] == "success":
    # Confirmer la réservation
```

## 📚 Documentation Additionnelle

- **FastAPI Docs**: http://localhost:8006/docs (Swagger)
- **Code Comments**: Tous les fichiers ont des commentaires en français détaillés
- **Pydantic Validation**: Voir `app/schemas/payment.py` pour les modèles DTOs

## 👤 Auteur

Service créé pour l'application COVOIT - Plateforme de covoiturage

## 📄 Licence

Propriétaire - COVOIT Inc.
