# 🚀 Trip Service - Guide de Démarrage Rapide

## ⚡ Démarrage en 5 minutes

### 1. Démarrer l'Infrastructure Docker

```bash
cd backend
docker-compose up -d
```

**Cela démarre**:
- ✅ PostgreSQL (auth, user, trip)
- ✅ Redis
- ✅ RabbitMQ
- ✅ API Gateway (port 8000)
- ✅ Auth Service (port 8001)
- ✅ User Service (port 8002)
- ✅ **Trip Service (port 8003)** ← NOUVEAU

### 2. Vérifier l'État

```bash
# Vérifier que tous les services sont en bonne santé
curl http://localhost:8000/health
curl http://localhost:8003/health

# Afficher les logs du Trip Service
docker logs trip-service -f
```

### 3. Accéder à la Documentation

- **Swagger UI** (Trip Service direct): http://localhost:8003/docs
- **Swagger UI** (via API Gateway): http://localhost:8000/api/trips/docs (en construction)
- **API Gateway health**: http://localhost:8000/health

---

## 📡 Tester l'API

### Créer un Trajet

```bash
curl -X POST http://localhost:8000/api/trips \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "Douala",
    "arrival_city": "Yaoundé",
    "departure_time": "2026-04-05T14:30:00",
    "total_seats": 4,
    "price_per_seat": 5000.0,
    "vehicle_model": "Toyota Fortuner 2020",
    "vehicle_plate": "CC1234",
    "is_prime": false,
    "comfort_options": ["ac", "wifi"]
  }'
```

**Réponse** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": "00000000-0000-0000-0000-000000000001",
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "available_seats": 4,
  "status": "active",
  ...
}
```

### Rechercher des Trajets

```bash
curl "http://localhost:8000/api/trips/search?from_city=Douala&to_city=Yaoundé&passenger_count=2&sort_by=price"
```

**Réponse** (200 OK):
```json
{
  "total_results": 1,
  "trips": [{...}],
  "filters_applied": {...}
}
```

### Récupérer un Trajet

```bash
curl http://localhost:8000/api/trips/550e8400-e29b-41d4-a716-446655440000
```

### Modifier un Trajet

```bash
curl -X PATCH http://localhost:8000/api/trips/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "price_per_seat": 4500.0,
    "status": "ongoing"
  }'
```

### Réserver des Places

```bash
curl -X POST "http://localhost:8000/api/trips/550e8400-e29b-41d4-a716-446655440000/book?passenger_count=2" \
  -H "Content-Type: application/json"
```

### Annuler un Trajet

```bash
curl -X DELETE http://localhost:8000/api/trips/550e8400-e29b-41d4-a716-446655440000
```

---

## 🗄️ Accéder à la Base de Données

### Via psql (ligne de commande)

```bash
# Se connecter à la base trip_db
psql postgresql://postgres:postgres@localhost:5434/trip_db

# Afficher tous les trajets
SELECT id, departure_city, arrival_city, available_seats, status FROM trips;

# Afficher les waypoints d'un trajet
SELECT * FROM waypoints WHERE trip_id = '550e8400-e29b-41d4-a716-446655440000';

# Afficher les options de confort
SELECT * FROM trip_comforts;

# Quitter psql
\q
```

### Via Un Client Graphique

- **DBeaver** : Télécharger depuis https://dbeaver.io
- **pgAdmin** : Accéder à http://localhost:15432 (optionnel, à ajouter)
- Connexion:
  - Host: localhost
  - Port: 5434
  - Database: trip_db
  - Username: postgres
  - Password: postgres

---

## 📊 Monitoring & Logs

### Logs du Trip Service

```bash
# Logs en direct
docker logs -f trip-service

# Dernières 50 lignes
docker logs --tail 50 trip-service
```

### Logs via Docker Desktop

- Ouvrir Docker Desktop
- Aller à "Containers"
- Cliquer sur "trip-service"
- Tab "Logs"

### Logs de la Base de Données

```bash
docker logs -f postgres-trip
```

---

## 🐛 Dépannage

### Erreur: Connection Refused (trip-service:8003)

**Symptôme**: `connection refused` lors de l'appel API

**Solution**:
```bash
# Vérifier que le service démarre correctement
docker logs trip-service

# Redémarrer le service
docker-compose up -d trip-service --force-recreate

# Vérifier avec healthcheck
curl http://localhost:8003/health
```

### Erreur: Database Connection Failed

**Symptôme**: `could not connect to server: Connection refused`

**Solution**:
```bash
# Vérifier que postgres-trip est en running
docker ps | grep postgres-trip

# Vérifier la santé de la base
docker exec postgres-trip pg_isready -U postgres

# Redémarrer la base
docker stop postgres-trip
docker start postgres-trip
```

### Erreur: 502 Bad Gateway

**Symptôme**: API Gateway retourne 502

**Solution**:
```bash
# Vérifier que Trip Service répond
curl http://trip-service:8003/health

# Vérifier la config de l'API Gateway
docker logs api-gateway | tail -20

# Redémarrer l'API Gateway
docker-compose up -d api-gateway --force-recreate
```

---

## 📈 Métriques & Statut

### Vérifier l'État Général

```bash
# Tous les conteneurs
docker-compose ps

# État des services
docker-compose logs --tail 1 | grep -E "Uvicorn|healthy"
```

**Attendu**:
```
postgres-trip   ✓ health: healthy
trip-service    ✓ running
api-gateway     ✓ running
```

### CPU & Mémoire

```bash
# Utilisation par service
docker stats trip-service postgres-trip
```

---

## 🔄 Redémarrage / Reset

### Redémarrer Trip Service et sa Base

```bash
# Redémarrer juste les services
docker-compose restart trip-service postgres-trip

# Force recreation (si modifications Dockerfile)
docker-compose up -d trip-service --build
```

### Reset Complet (données perdues)

```bash
# Arrêter tous les services
docker-compose down

# Supprimer les volumes (données)
docker-compose down -v

# Redémarrer fresh
docker-compose up -d
```

---

## 🔐 Sécurité (Development Only)

⚠️ **Attention**: Les configurations actuelles ne sont PAS sécurisées. Pour production:

1. **Changer SECRET_KEY**
   ```bash
   # Générer une clé sécurisée
   openssl rand -hex 32
   
   # Remplacer dans docker-compose.yml et .env
   ```

2. **Réduire allow_origins CORS**
   ```python
   # Remplacer ["*"] par domaines spécifiques
   allow_origins=["https://monapp.com"]
   ```

3. **Ajouter Rate Limiting**
   ```python
   # À implémenter dans main.py
   ```

4. **Utiliser HTTPS**
   ```bash
   # Configurer reverse proxy (Nginx) avec SSL
   ```

---

## 📚 Architecture Rappel

```
CLIENT (Flutter App)
    ↓
API Gateway (localhost:8000)
    ├→ /auth/* → Auth Service (8001)
    ├→ /users/* → User Service (8002)
    └→ /trips/* → Trip Service (8003) ← NOUVEAU
         ↓
     PostgreSQL trip_db (5434)
```

---

## ✅ Prochaines Étapes

**Phase 2**: Booking Service (réservations)

```bash
# À venir...
cd backend/services/booking
```

**Phase 3**: Payment Service (paiements)  
**Phase 4**: Review Service (évaluations)  
**Phase 5**: Chat Service (messages)  
**Phase 6**: Notification Service (notifications)  
**Phase 7**: Driver Stats (statistiques)

---

## 💡 Tips & Tricks

### Créer une Meilleure Requête JSON

Créer un fichier `test.json`:
```json
{
  "departure_city": "Douala",
  "arrival_city": "Yaoundé",
  "departure_time": "2026-04-05T14:30:00",
  "total_seats": 4,
  "price_per_seat": 5000.0,
  "vehicle_model": "Toyota Fortuner",
  "vehicle_plate": "CC1234",
  "is_prime": false
}
```

Puis:
```bash
curl -X POST http://localhost:8000/api/trips \
  -H "Content-Type: application/json" \
  -d @test.json
```

### Utiliser HTTPie (Plus Lisible)

```bash
# Installer
pip install httpie

# Utiliser
http POST http://localhost:8000/api/trips < test.json
http GET http://localhost:8000/api/trips/search from_city=Douala to_city=Yaoundé
```

### Utiliser Postman

Importer dans Postman : [Collection URL à générer]

---

## 📞 Support

Pour des questions:
1. Consulter [README.md](services/trip/README.md)
2. Regarder les commentaires en français dans le code
3. Vérifier les logs
4. Lire la documentation Swagger

---

**Happy Coding! 🎉**

P.S. Tous les fichiers ont des commentaires en français pour l'apprentissage!
