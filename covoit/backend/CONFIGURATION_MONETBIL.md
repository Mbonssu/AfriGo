# Configuration Monetbil - Guide complet

## 📋 Informations de configuration

### Identifiants Monetbil (déjà configurés dans le code)
- **Service Key**: `LIXGD0SbK4MIFyAu4TmohsuSXvXW0heS`
- **Service Secret**: `nbp2S00FgdspHbv4LOSWt0VroWGllTqcy0wj8tu1qDIBwtQ4XyGkrLNYEpJk79V1`

## 🌐 URLs à configurer dans le dashboard Monetbil

### 1. URL de notification (Notify URL) - OBLIGATOIRE

C'est l'URL que Monetbil appellera automatiquement pour notifier le statut du paiement (côté serveur).

#### Pour le développement local (avec ngrok)
```
https://VOTRE-SOUS-DOMAINE.ngrok-free.app/api/payments/notify/monetbil
```

#### Pour la production
```
https://api.afrigo.cm/api/payments/notify/monetbil
```

⚠️ **IMPORTANT** : Cette URL locale ne fonctionnera PAS car Monetbil ne peut pas accéder à ton réseau local. Tu DOIS utiliser ngrok (voir section ci-dessous).

### 2. URL de succès (Success URL) - OBLIGATOIRE

C'est l'URL où l'utilisateur sera redirigé après un paiement **réussi**.

#### Pour l'application mobile (deep link)
```
afrigo://payment/success
```

#### Pour un site web (si tu en as un)
```
https://afrigo.cm/payment/success
```

### 3. URL d'échec (Failure URL) - OBLIGATOIRE

C'est l'URL où l'utilisateur sera redirigé après un paiement **échoué**.

#### Pour l'application mobile (deep link)
```
afrigo://payment/failed
```

#### Pour un site web
```
https://afrigo.cm/payment/failed
```

### 4. URL d'annulation (Cancel URL) - OPTIONNELLE

C'est l'URL où l'utilisateur sera redirigé s'il **annule** le paiement.

#### Pour l'application mobile (deep link)
```
afrigo://payment/cancelled
```

#### Pour un site web
```
https://afrigo.cm/payment/cancelled
```

### 5. URL de retour générique (Return URL) - OPTIONNELLE

URL de retour par défaut si les autres ne sont pas spécifiées.

```
afrigo://payment/return
```

## 🔧 Configuration dans le dashboard Monetbil

### Étape 1 : Se connecter au dashboard
1. Va sur https://www.monetbil.com/
2. Connecte-toi avec ton compte
3. Va dans **"Paramètres"** ou **"Settings"**

### Étape 2 : Configurer les URLs
Dans la section **"Configuration du service"** ou **"Service Configuration"** :

1. **Notify URL** (URL de notification) :
   - Pour le développement : `https://VOTRE-NGROK.ngrok-free.app/api/payments/notify/monetbil`
   - Pour la production : `https://api.afrigo.cm/api/payments/notify/monetbil`

2. **Return URL** (URL de retour) :
   - `afrigo://payment/success`

3. **Méthode de notification** :
   - Sélectionne **POST** (recommandé) ou **GET**

4. **Enregistrer** les modifications

## 🚀 Utiliser ngrok pour le développement local

### Pourquoi ngrok ?
Monetbil a besoin d'une URL publique pour envoyer les notifications. Ton serveur local (`192.168.45.54:8000`) n'est pas accessible depuis Internet. ngrok crée un tunnel sécurisé qui expose ton serveur local.

### Installation de ngrok

#### Sur Linux
```bash
# Télécharger ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz

# Extraire
tar -xvzf ngrok-v3-stable-linux-amd64.tgz

# Déplacer dans /usr/local/bin
sudo mv ngrok /usr/local/bin/

# Vérifier l'installation
ngrok version
```

### Configuration de ngrok

1. **Créer un compte gratuit** sur https://ngrok.com/
2. **Récupérer ton authtoken** depuis le dashboard ngrok
3. **Configurer l'authtoken** :
```bash
ngrok config add-authtoken VOTRE_TOKEN_ICI
```

### Démarrer ngrok

```bash
# Exposer le port 8000 (API Gateway)
ngrok http 8000
```

Tu verras quelque chose comme :
```
Session Status                online
Account                       ton-email@example.com
Version                       3.x.x
Region                        United States (us)
Latency                       -
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://abc123.ngrok-free.app -> http://localhost:8000
```

### Utiliser l'URL ngrok

1. **Copie l'URL HTTPS** : `https://abc123.ngrok-free.app`
2. **Configure dans Monetbil** :
   ```
   https://abc123.ngrok-free.app/api/payments/notify/monetbil
   ```
3. **Mets à jour le code** (optionnel pour les tests) :
   ```python
   MONETBIL_NOTIFY_URL: str = Field(
       default="https://abc123.ngrok-free.app/api/payments/notify/monetbil",
   )
   ```

⚠️ **Note** : L'URL ngrok change à chaque redémarrage avec le plan gratuit. Tu devras mettre à jour la configuration Monetbil à chaque fois.

## 📱 Configuration dans l'application Flutter

### Fichier de configuration
Le fichier `lib/core/constants/api_endpoints.dart` contient déjà les endpoints :

```dart
// Paiement
static const String initPayment = '$_payments/initiate';
static const String verifyPayment = '$_payments/verify';
static const String paymentHistory = '$_payments/history';
```

### Flux de paiement

1. **Initier le paiement** :
   ```dart
   POST /api/payments/initiate
   {
     "user_id": "uuid",
     "amount": 5000,
     "payment_type": "booking",
     "booking_id": "uuid"
   }
   ```

2. **Réponse avec payment_url** :
   ```json
   {
     "payment_id": "uuid",
     "payment_url": "https://www.monetbil.com/pay/...",
     "status": "pending"
   }
   ```

3. **Ouvrir payment_url dans le navigateur** :
   - L'utilisateur effectue le paiement
   - Monetbil notifie ton serveur via l'URL de notification
   - L'utilisateur est redirigé vers `afrigo://payment/success`

4. **Vérifier le statut** :
   ```dart
   POST /api/payments/verify
   {
     "payment_id": "uuid"
   }
   ```

## 🧪 Tester la configuration

### Script de test
```bash
# Créer un paiement de test
curl -X POST http://192.168.45.54:8000/api/payments/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "amount": 100,
    "payment_type": "booking",
    "booking_id": "550e8400-e29b-41d4-a716-446655440001"
  }'
```

### Vérifier les logs
```bash
# Logs du service de paiement
docker compose logs -f payment-service

# Logs de l'API gateway
docker compose logs -f api-gateway
```

### Tester la notification Monetbil
Une fois ngrok configuré, tu peux tester manuellement :

```bash
# Simuler une notification Monetbil
curl -X POST https://VOTRE-NGROK.ngrok-free.app/api/payments/notify/monetbil \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "uuid-du-paiement",
    "status": "success",
    "transaction_id": "MTN123456789"
  }'
```

## 📊 Monitoring avec ngrok

Quand ngrok est actif, tu peux voir toutes les requêtes sur :
```
http://127.0.0.1:4040
```

Cela te permet de :
- Voir les notifications envoyées par Monetbil
- Déboguer les problèmes
- Rejouer les requêtes

## 🔒 Sécurité

### Vérification de la signature Monetbil
Le service vérifie automatiquement la signature des notifications Monetbil avec le `SERVICE_SECRET`.

### En production
1. Utilise HTTPS obligatoirement
2. Configure un domaine fixe (pas ngrok)
3. Ajoute une authentification supplémentaire si nécessaire
4. Stocke les secrets dans des variables d'environnement

## 📝 Checklist de configuration

- [ ] Identifiants Monetbil configurés dans le code
- [ ] ngrok installé et configuré
- [ ] ngrok démarré (`ngrok http 8000`)
- [ ] URL ngrok copiée
- [ ] URL de notification configurée dans le dashboard Monetbil
- [ ] URL de retour configurée (deep link)
- [ ] Services Docker démarrés (`docker compose up -d`)
- [ ] Test de création de paiement réussi
- [ ] Test de notification Monetbil réussi

## 🆘 Problèmes courants

### Monetbil ne peut pas joindre mon serveur
- ✅ Vérifie que ngrok est bien démarré
- ✅ Vérifie que l'URL dans Monetbil est correcte
- ✅ Vérifie les logs ngrok sur http://127.0.0.1:4040

### Les notifications ne sont pas reçues
- ✅ Vérifie que l'endpoint `/api/payments/notify/monetbil` existe
- ✅ Vérifie les logs du service de paiement
- ✅ Vérifie que le service de paiement est bien démarré

### Erreur de signature
- ✅ Vérifie que le `SERVICE_SECRET` est correct
- ✅ Vérifie que Monetbil envoie bien la signature

## 📞 Support

- Documentation Monetbil : https://www.monetbil.com/documentation
- Support Monetbil : support@monetbil.com
- Dashboard Monetbil : https://www.monetbil.com/dashboard
