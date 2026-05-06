# 💳 Système de Paiement Simulé - AfriGo

## 📋 Vue d'ensemble

Le système de paiement d'AfriGo fonctionne en **mode simulation** pour permettre de tester toutes les fonctionnalités sans intégration bancaire réelle. Tous les paiements sont simulés avec MTN Mobile Money et Orange Money.

---

## 🔄 Flux de Paiement pour les Trajets

### **1. Passager dépose des fonds** (`deposit_screen.dart`)
- Entre le montant à payer
- Choisit MTN ou Orange Money
- Clique sur "Continuer vers le paiement"

### **2. Simulation de paiement** (`payment_simulation_screen.dart`)
- Affiche les détails du paiement
- Bouton "Payer maintenant"
- Animation de traitement (3 secondes)
- Message "Paiement réussi !"

### **3. Fonds en séquestre** (`escrow_status_screen.dart`)
- Affiche "Fonds bloqués en séquestre"
- Statut : "En attente de validation"
- Étapes du processus visibles

### **4. Client libère les fonds** (`release_funds_screen.dart`)
- **Le client clique sur "Déposer"**
- Confirmation de la libération
- Animation de transfert (2 secondes)
- Message "Fonds libérés !"

### **5. Chauffeur reçoit les fonds** (`driver_wallet_screen.dart`)
- Solde disponible mis à jour
- Fonds visibles dans le portefeuille
- Historique des transactions

### **6. Chauffeur retire les fonds** (`withdrawal_screen.dart`)
- Entre le montant à retirer
- Choisit MTN ou Orange Money
- Entre son numéro de téléphone
- Clique sur "Retirer les fonds"
- Message "Transfert effectué !"

---

## ⭐ Abonnement Prime

### **Écran d'abonnement** (`prime_subscription_screen.dart`)

#### Plans disponibles :
- **Mensuel** : 5 000 FCFA / mois
- **Trimestriel** : 12 000 FCFA / 3 mois (économie 20%)
- **Annuel** : 40 000 FCFA / 12 mois (économie 33%)

#### Avantages Prime :
- ✅ Badge vérifié
- ✅ Accès au forum exclusif
- ✅ Visibilité accrue (priorité dans les recherches)
- ✅ Support prioritaire 24/7
- ✅ Statistiques avancées

#### Processus :
1. Choisir un plan
2. Choisir MTN ou Orange Money
3. Cliquer sur "S'abonner"
4. Animation (3 secondes)
5. Message "Bienvenue dans Prime !"
6. Toutes les fonctionnalités Prime débloquées

---

## 🔓 Système de Déblocage des Fonctionnalités

### **Provider de simulation** (`payment_simulation_provider.dart`)

Gère l'état global des paiements et débloque les fonctionnalités :

```dart
// Activer Prime
ref.read(paymentSimulationProvider.notifier).activatePrime();

// Compléter un paiement
ref.read(paymentSimulationProvider.notifier).completePayment(bookingId);

// Débloquer une fonctionnalité spécifique
ref.read(paymentSimulationProvider.notifier).unlockFeature('chat');

// Tout débloquer (mode démo)
ref.read(paymentSimulationProvider.notifier).unlockAll();
```

### **Widget de garde** (`payment_gate_widget.dart`)

Protège les fonctionnalités payantes :

```dart
PaymentGate(
  featureName: 'prime_forum',
  title: 'Forum Prime',
  description: 'Accédez au forum exclusif des membres Prime',
  icon: Icons.forum_rounded,
  requiresPrime: true,
  child: ForumScreen(), // Écran protégé
)
```

---

## 🎯 Fonctionnalités Débloquables

### **Fonctionnalités Prime** (requiresPrime: true)
- `prime_forum` - Forum exclusif
- `prime_badge` - Badge vérifié
- `priority_listing` - Priorité dans les recherches
- `advanced_stats` - Statistiques avancées

### **Fonctionnalités avec paiement** (requiresPayment: true)
- `chat` - Messagerie avec le chauffeur
- `tracking` - Suivi GPS en temps réel
- `caution` - Système de caution
- `booking_[id]` - Réservation spécifique

---

## 📱 Méthodes de Paiement Simulées

### **MTN Mobile Money**
- Couleur : Jaune (#FFCC00)
- Icône : `phone_android_rounded`
- Simulation : 3 secondes

### **Orange Money**
- Couleur : Orange (#FF6600)
- Icône : `phone_iphone_rounded`
- Simulation : 3 secondes

---

## 🔧 Utilisation dans le Code

### **1. Vérifier si Prime est actif**
```dart
final isPrime = ref.watch(isPrimeActiveProvider);

if (isPrime) {
  // Afficher le badge Prime
}
```

### **2. Vérifier si une fonctionnalité est débloquée**
```dart
final isUnlocked = ref.watch(isFeatureUnlockedProvider('chat'));

if (isUnlocked) {
  // Permettre l'accès au chat
}
```

### **3. Protéger un écran**
```dart
return PaymentGate(
  featureName: 'tracking',
  title: 'Suivi GPS',
  description: 'Suivez votre trajet en temps réel',
  icon: Icons.location_on_rounded,
  requiresPayment: true,
  child: TrackingScreen(),
);
```

### **4. Débloquer après un paiement**
```dart
// Après simulation de paiement réussie
ref.read(paymentSimulationProvider.notifier).completePayment(bookingId);
ref.read(paymentSimulationProvider.notifier).unlockFeature('chat');
```

---

## 🎨 Écrans Créés

| Écran | Fichier | Description |
|-------|---------|-------------|
| Dépôt | `deposit_screen.dart` | Passager entre le montant |
| Simulation | `payment_simulation_screen.dart` | Traitement du paiement |
| Séquestre | `escrow_status_screen.dart` | Fonds bloqués |
| Libération | `release_funds_screen.dart` | Client libère les fonds |
| Portefeuille | `driver_wallet_screen.dart` | Solde du chauffeur |
| Retrait | `withdrawal_screen.dart` | Chauffeur retire |
| Prime | `prime_subscription_screen.dart` | Abonnement Prime |

---

## ⚙️ Configuration

### **Mode Démo (tout débloqué)**
Pour tester l'application avec toutes les fonctionnalités débloquées :

```dart
// Dans main.dart ou un écran de debug
ref.read(paymentSimulationProvider.notifier).unlockAll();
```

### **Réinitialiser**
Pour revenir à l'état initial :

```dart
ref.read(paymentSimulationProvider.notifier).reset();
```

---

## 🚀 Intégration Future (Production)

Quand vous serez prêt à intégrer les vrais paiements :

1. **Remplacer les simulations** par les vraies API :
   - MTN Mobile Money API
   - Orange Money API

2. **Connecter au backend** :
   - Service de paiement (`payment-service`)
   - Gestion du séquestre
   - Webhooks de confirmation

3. **Sécurité** :
   - Tokens de paiement
   - Vérification des transactions
   - Logs d'audit

4. **Garder le provider** :
   - Le `paymentSimulationProvider` peut devenir `paymentProvider`
   - Même logique de déblocage
   - Juste changer la source des données (API au lieu de local)

---

## 📝 Notes Importantes

- ✅ **Tous les paiements sont simulés** - Aucune transaction réelle
- ✅ **MTN et Orange Money** - Simulation complète des deux méthodes
- ✅ **Déblocage automatique** - Les fonctionnalités se débloquent après simulation
- ✅ **Mode démo disponible** - `unlockAll()` pour tout débloquer
- ✅ **Visibilité globale** - Toutes les fonctionnalités sont accessibles en simulation

---

## 🎯 Checklist de Test

- [ ] Passager peut déposer des fonds (MTN)
- [ ] Passager peut déposer des fonds (Orange)
- [ ] Fonds apparaissent en séquestre
- [ ] Client peut libérer les fonds
- [ ] Chauffeur voit les fonds disponibles
- [ ] Chauffeur peut retirer (MTN)
- [ ] Chauffeur peut retirer (Orange)
- [ ] Abonnement Prime (Mensuel)
- [ ] Abonnement Prime (Trimestriel)
- [ ] Abonnement Prime (Annuel)
- [ ] Forum Prime débloqué après abonnement
- [ ] Badge Prime visible après abonnement
- [ ] Fonctionnalités payantes débloquées après paiement
- [ ] Mode démo `unlockAll()` fonctionne

---

## 📞 Support

Pour toute question sur le système de paiement simulé, consultez :
- `payment_simulation_provider.dart` - Logique de déblocage
- `payment_gate_widget.dart` - Protection des fonctionnalités
- Les écrans dans `lib/screens/payment/`
