# AfriGo Admin Panel

Panel d'administration web pour la plateforme AfriGo, construit avec React, Vite et Tailwind CSS.

## 🎨 Design

Le panel respecte la charte graphique de l'application mobile AfriGo :
- **Couleur principale** : Vert (#1D9E75)
- **Couleur secondaire** : Prime/Orange (#EF9F27)
- **Police** : Outfit (Google Fonts)
- **Style** : Design épuré et moderne avec des cartes arrondies

## 🚀 Installation

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm run dev

# Build pour la production
npm run build
```

## 📱 Fonctionnalités

### Tableau de bord
- Vue d'ensemble des statistiques (utilisateurs, chauffeurs, trajets, revenus)
- Graphiques de tendances (trajets et revenus par jour)
- Liste des trajets récents

### Gestion des utilisateurs
- Liste complète des utilisateurs
- Filtrage par rôle (chauffeur/passager) et statut
- Recherche par nom ou email
- Détails des utilisateurs (contact, nombre de trajets, date d'inscription)

### Gestion des chauffeurs
- Vue en grille des chauffeurs
- Informations sur les véhicules
- Statut Prime et vérification
- Notes et nombre de trajets

### Gestion des trajets
- Liste des trajets actifs, en cours et terminés
- Détails : itinéraire, date, places disponibles, prix
- Barre de progression des réservations

### Gestion des réservations
- Liste de toutes les réservations
- Statuts : en attente, confirmé, terminé
- Détails passager, chauffeur, montant

### Gestion des paiements
- Statistiques des paiements (complétés, en attente, échoués)
- Liste des transactions avec références
- Méthodes de paiement (MTN, Orange Money)

### Paramètres
- Configuration générale de la plateforme
- Paramètres de notifications
- Configuration des paiements (commission, caution)
- Configuration email (SMTP)

## 🔐 Authentification

**Identifiants de test :**
- Email : `admin@afrigo.cm`
- Mot de passe : `admin123`

## 🛠️ Technologies

- **React 18** - Framework UI
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **React Router** - Navigation
- **Recharts** - Graphiques
- **Lucide React** - Icônes
- **Axios** - HTTP client

## 📁 Structure du projet

```
admin-panel/
├── src/
│   ├── components/
│   │   └── Layout.jsx          # Layout principal avec sidebar
│   ├── pages/
│   │   ├── Login.jsx           # Page de connexion
│   │   ├── Dashboard.jsx       # Tableau de bord
│   │   ├── Users.jsx           # Gestion utilisateurs
│   │   ├── Drivers.jsx         # Gestion chauffeurs
│   │   ├── Trips.jsx           # Gestion trajets
│   │   ├── Bookings.jsx        # Gestion réservations
│   │   ├── Payments.jsx        # Gestion paiements
│   │   └── Settings.jsx        # Paramètres
│   ├── App.jsx                 # Composant principal
│   ├── main.jsx                # Point d'entrée
│   └── index.css               # Styles globaux
├── index.html
├── package.json
├── vite.config.js
├── tailwind.config.js
└── postcss.config.js
```

## 🔗 Intégration Backend

Pour connecter le panel au backend AfriGo :

1. Créer un fichier `src/api/client.js` :
```javascript
import axios from 'axios'

const apiClient = axios.create({
  baseURL: 'http://192.168.45.54:8000/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export default apiClient
```

2. Remplacer les données simulées par des appels API réels dans chaque page

## 📝 TODO

- [ ] Intégration avec l'API backend
- [ ] Authentification JWT réelle
- [ ] Gestion des permissions admin
- [ ] Export de données (CSV, PDF)
- [ ] Notifications en temps réel
- [ ] Mode sombre
- [ ] Pagination des listes
- [ ] Filtres avancés
- [ ] Graphiques plus détaillés
- [ ] Logs d'activité admin

## 🎯 Prochaines étapes

1. Créer les endpoints admin dans le backend
2. Implémenter l'authentification admin
3. Connecter toutes les pages aux APIs
4. Ajouter la gestion des permissions
5. Déployer sur un serveur web

## 📄 Licence

Propriétaire - AfriGo © 2026
