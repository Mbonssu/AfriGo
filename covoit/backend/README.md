# Covoit Microservices Backend

Architecture microservices Python FastAPI pour l'app Covoit (covoiturage).

## 🏗️ Architecture

```
API Gateway (8000) → Router centralisé
├─ Auth Service (8001) → Authentication, JWT
├─ User Service (8002) → Profils utilisateurs
├─ [Future] Trip Service (8003)
├─ [Future] Driver Service (8004)
├─ [Future] Payment Service (8006)
└─ [Future] Chat Service (8008)

Infrastructure:
├─ PostgreSQL (Auth & User DBs)
├─ Redis (cache, sessions)
├─ RabbitMQ (async events)
└─ Elasticsearch (search)
```

## 📋 Prérequis

- Docker & Docker Compose 20.10+
- Python 3.11+ (pour dev local)
- PostgreSQL 15+ (si dev sans Docker)
- Redis 7+ (si dev sans Docker)

## 🚀 Démarrage Rapide (Local avec Docker)

### 1. Clone & Setup

```bash
cd backend/
cp .env.example .env
```

### 2. Démarrer tous les services

```bash
docker-compose up -d
```

Cela démarre :

- PostgreSQL (Auth) sur port 5432
- PostgreSQL (User) sur port 5433
- Redis sur port 6379
- RabbitMQ sur port 5672 + management 15672
- API Gateway sur port 8000
- Auth Service sur port 8001
- User Service sur port 8002

### 3. Vérifier les services

```bash
# Health checks
curl http://localhost:8000/health
curl http://localhost:8001/health
curl http://localhost:8002/health

# RabbitMQ Management UI
http://localhost:15672 (guest/guest)
```

## 📚 Endpoints Phase 1

### Auth Service

**Register**

```bash
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "phone": "+212612345678",
  "role": "passenger"  # ou "driver"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLC...",
  "refresh_token": "...",
  "token_type": "bearer",
  "user": {
    "id": "uuid-...",
    "email": "user@example.com",
    "phone": "+212612345678",
    "role": "passenger",
    "is_active": true,
    "created_at": "2026-04-01T..."
  }
}
```

**Login**

```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}

Response: (identique à register)
```

### User Service

**Get Profile**

```bash
GET /api/users/profile/{user_id}
Authorization: Bearer {access_token}

Response:
{
  "id": "uuid-...",
  "user_id": "uuid-...",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+212612345678",
  "profile_picture_url": null,
  "bio": "Chauffeur passionné",
  "rating": 5.0,
  "total_reviews": "0",
  "created_at": "2026-04-01T..."
}
```

**Update Profile**

```bash
PATCH /api/users/profile/{user_id}
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "first_name": "Jean",
  "last_name": "Due",
  "bio": "Updated bio"
}
```

**Create Driver Profile**

```bash
POST /api/users/{user_id}/driver
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "license_number": "SN1234567890",
  "vehicle_model": "Toyota Prius 2023",
  "vehicle_plate": "DK-7777-H",
  "is_prime": "false"
}

Response:
{
  "id": "uuid-...",
  "user_id": "uuid-...",
  "license_number": "SN1234567890",
  "vehicle_model": "Toyota Prius 2023",
  "vehicle_plate": "DK-7777-H",
  "is_prime": "false",
  "total_trips": "0",
  "total_earnings": 0.0,
  "rating": 5.0
}
```

## 🛠️ Development Local (sans Docker)

### 1. Setup venv

```bash
python -m venv venv
source venv/bin/activate  # ou venv\Scripts\activate (Windows)
pip install -r requirements.txt
```

### 2. Setup Postgres

```bash
# Créer bases de données
psql -U postgres
CREATE DATABASE auth_db;
CREATE DATABASE user_db;
\q
```

### 3. Démarrer les services

```bash
# Terminal 1: Auth Service
cd services/auth
uvicorn app.main:app --port 8001 --reload

# Terminal 2: User Service
cd services/user
uvicorn app.main:app --port 8002 --reload

# Terminal 3: API Gateway
cd api-gateway
uvicorn app.main:app --port 8000 --reload
```

## 🐳 Docker Compose Commands

```bash
# Démarrer tous les services
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f auth-service

# Arrêter tout
docker-compose down

# Arrêter et supprimer volumes
docker-compose down -v

# Rebuild images
docker-compose build --no-cache api-gateway auth-service user-service
```

## ☸️ Kubernetes Deployment

### 1. Créer le namespace et secrets

```bash
kubectl apply -f k8s/secrets.yaml
```

### 2. Déployer les services

```bash
kubectl apply -f k8s/api-gateway.yaml
kubectl apply -f k8s/auth-service.yaml
kubectl apply -f k8s/user-service.yaml
```

### 3. Vérifier déploiement

```bash
kubectl get pods -n covoit
kubectl get svc -n covoit
kubectl describe pod api-gateway-xxxxx -n covoit
kubectl logs api-gateway-xxxxx -n covoit
```

### 4. Port-forward pour accès local

```bash
kubectl port-forward -n covoit svc/api-gateway 8000:80
```

## 📊 Structure Fichiers

```
backend/
├── api-gateway/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/config.py
│   │   └── api/routes/
│   │       ├── auth.py
│   │       └── users.py
│   └── Dockerfile
├── services/
│   ├── auth/
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── api/routes/auth.py
│   │   │   ├── models/user.py
│   │   │   ├── schemas/auth.py
│   │   │   ├── services/auth_service.py
│   │   │   └── db/session.py
│   │   └── Dockerfile
│   └── user/
│       ├── app/
│       │   ├── main.py
│       │   ├── api/routes/users.py
│       │   ├── models/user_profile.py
│       │   ├── schemas/user.py
│       │   ├── services/user_service.py
│       │   └── db/session.py
│       └── Dockerfile
├── k8s/
│   ├── api-gateway.yaml
│   ├── auth-service.yaml
│   ├── user-service.yaml
│   └── secrets.yaml
├── docker-compose.yml
├── requirements.txt
├── .env.example
└── README.md
```

## 🔐 Sécurité

⚠️ **Production Checklist:**

- [ ] Changer `SECRET_KEY` dans `settings` (lire depuis env)
- [ ] HTTPS/TLS obligatoire
- [ ] Rate limiting sur API Gateway
- [ ] CORS correctement configuré
- [ ] Secrets stockés en env vars (pas en code)
- [ ] Logs sensibles filtré (mots de passe, tokens)
- [ ] Validations input strict
- [ ] CSRF tokens pour endpoints POST
- [ ] Scan vulnérabilités régulier (`pip-audit`)

## 🧪 Testing

```bash
# Unit tests
pytest services/auth/tests/
pytest services/user/tests/

# Integration tests
pytest tests/integration/

# Coverage
pytest --cov=app services/auth/tests/
```

## 📈 Monitoring (Dev)

```bash
# Logs service
docker-compose logs auth-service | tail -100

# Metrics (future avec Prometheus)
curl http://localhost:8001/metrics

# Health status
curl http://localhost:8000/health
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## Phase 2 (À venir)

- [ ] Trip Service
- [ ] Driver Service
- [ ] Passenger Service
- [ ] Payment Service (Orange/Airtel Money)
- [ ] Notification Service
- [ ] Chat Service (WebSocket)
- [ ] Rating Service
- [ ] Search Service (Elasticsearch)

## 📞 Support

Pour questions/bugs, ouvrir issue ou contacter l'équipe DevOps.

---

**Last Updated**: 2026-04-01
**Version**: Phase 1 - API Gateway + Auth + User Services
