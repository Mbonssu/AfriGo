# 🧪 Tests API AfriGo - Guide Rapide

## 📱 Configuration
**URL de base :** `http://192.168.30.113:8000`

---

## 1️⃣ Health Check (Vérifier que le serveur fonctionne)

```bash
curl http://192.168.30.113:8000/health
```

**Réponse attendue :**
```json
{"status":"ok","service":"api-gateway"}
```

---

## 2️⃣ Inscription (Register)

```bash
curl -X POST http://192.168.30.113:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nouveau@test.com",
    "password": "#Kimmich911",
    "phone": "652141260",
    "role": "passenger"
  }'
```

**Réponse attendue (200 OK) :**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": "uuid-here",
    "email": "nouveau@test.com",
    "phone": "652141260",
    "role": "passenger",
    "is_active": true,
    "created_at": "2026-05-05T..."
  }
}
```

**Erreurs possibles :**
- `400 Bad Request` : Email déjà utilisé
- `422 Unprocessable Entity` : Données invalides (email, téléphone, mot de passe)

---

## 3️⃣ Connexion (Login)

```bash
curl -X POST http://192.168.30.113:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nouveau@test.com",
    "password": "#Kimmich911"
  }'
```

**Réponse attendue (200 OK) :**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": { ... }
}
```

---

## 4️⃣ Profil utilisateur (Me)

**⚠️ Remplacez `YOUR_TOKEN` par le token reçu lors de la connexion**

```bash
curl http://192.168.30.113:8000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 5️⃣ Rechercher des trajets

```bash
curl "http://192.168.30.113:8000/api/trips/search?departure_city=Douala&arrival_city=Yaoundé&departure_date=2026-05-10"
```

---

## 6️⃣ Publier un trajet (Chauffeur)

**⚠️ Nécessite un token de chauffeur**

```bash
curl -X POST http://192.168.30.113:8000/api/trips \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "Douala",
    "arrival_city": "Yaoundé",
    "departure_time": "2026-05-10T08:00:00",
    "total_seats": 4,
    "price_per_seat": 3000,
    "vehicle_model": "Toyota Corolla",
    "vehicle_plate": "LT-1234-AB"
  }'
```

---

## 7️⃣ Réserver un trajet (Passager)

**⚠️ Remplacez `TRIP_ID` par l'ID d'un trajet existant**

```bash
curl -X POST http://192.168.30.113:8000/api/bookings \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "trip_id": "TRIP_ID",
    "seats_booked": 1,
    "pickup_point": "Rond-point Deido",
    "dropoff_point": "Carrefour Bastos"
  }'
```

---

## 📱 Tester depuis votre téléphone

### Option 1 : Application Postman Mobile
1. Téléchargez **Postman** depuis le Play Store
2. Importez le fichier `AfriGo_API.postman_collection.json`
3. Testez les requêtes

### Option 2 : Application HTTP Request Tester
1. Téléchargez **HTTP Request Tester** ou **API Tester**
2. Créez une requête POST vers `http://192.168.30.113:8000/api/auth/register`
3. Headers : `Content-Type: application/json`
4. Body : 
```json
{
  "email": "test456@test.com",
  "password": "#Kimmich911",
  "phone": "652141260",
  "role": "passenger"
}
```

### Option 3 : Navigateur du téléphone
Ouvrez : `http://192.168.30.113:8000/health`

---

## 🔧 Format des données

### Numéro de téléphone (Cameroun)
- ✅ `652141260` (9 chiffres, commence par 6-9)
- ✅ `237652141260` (avec préfixe pays)
- ✅ `+237652141260` (avec +)
- ❌ `0652141260` (pas de 0 au début)

### Mot de passe
- Minimum 8 caractères
- Au moins 1 majuscule
- Au moins 1 chiffre
- Au moins 1 caractère spécial (!@#$%^&*...)

### Rôle
- `passenger` (passager)
- `driver` (chauffeur)

---

## 🐛 Dépannage

### Timeout / Pas de réponse
```bash
# Vérifier que le serveur est accessible
ping 192.168.30.113

# Vérifier que le port 8000 est ouvert
curl -v http://192.168.30.113:8000/health
```

### Erreur 400 "User already exists"
L'email est déjà utilisé. Essayez avec un autre email.

### Erreur 422 "Unprocessable Entity"
Vérifiez le format de vos données (email, téléphone, mot de passe).

### Erreur 503 "Service Unavailable"
Un des microservices (auth, user, trip...) ne répond pas. Vérifiez les logs :
```bash
docker logs covoit-auth
docker logs covoit-user
```

---

## 📊 Vérifier les logs en temps réel

```bash
# Gateway
docker logs -f covoit-gateway

# Service Auth
docker logs -f covoit-auth

# Tous les services
docker compose logs -f
```
