# Mode Sombre - Documentation Technique

## Architecture

Le mode sombre est implémenté avec :
- **Tailwind CSS** : Utilise la stratégie `class` pour le mode sombre
- **React Context** : `ThemeContext` pour gérer l'état global du thème
- **localStorage** : Persistance du choix de l'utilisateur
- **Préférence système** : Détection automatique via `prefers-color-scheme`

## Fichiers Modifiés

### 1. `tailwind.config.js`
```javascript
darkMode: 'class', // Active le mode sombre basé sur la classe 'dark'
```

### 2. `src/contexts/ThemeContext.jsx`
Context React qui gère :
- État `isDark` (boolean)
- Fonction `toggleTheme()` pour basculer
- Synchronisation avec `document.documentElement.classList`
- Sauvegarde dans localStorage

### 3. `index.html`
Script inline pour éviter le FOUC (Flash of Unstyled Content) :
```javascript
(function() {
  const theme = localStorage.getItem('admin_theme');
  if (theme === 'dark' || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark');
  }
})();
```

### 4. `src/index.css`
Classes CSS avec variantes dark :
```css
.card {
  @apply bg-white dark:bg-gray-800 ...;
}

.input {
  @apply bg-gray-50 dark:bg-gray-700 ...;
}
```

### 5. Composants
Tous les composants utilisent les classes Tailwind avec variantes `dark:` :
```jsx
<h1 className="text-gray-900 dark:text-white">Titre</h1>
<p className="text-gray-600 dark:text-gray-400">Texte</p>
<div className="bg-white dark:bg-gray-800">Contenu</div>
```

## Palette de Couleurs

### Mode Clair
- Background principal : `bg-gray-50` (#F1EFE8)
- Cards : `bg-white` (#FFFFFF)
- Texte principal : `text-gray-900` (#2C2C2A)
- Texte secondaire : `text-gray-600` (#5F5E5A)
- Bordures : `border-gray-100/30`

### Mode Sombre
- Background principal : `bg-gray-900` (#111110)
- Cards : `bg-gray-800` (#1A1A18)
- Texte principal : `text-white` (#FFFFFF)
- Texte secondaire : `text-gray-400` (#888780)
- Bordures : `border-gray-700/30`

### Couleurs de Marque (Identiques)
- Vert : `#1D9E75` (primary)
- Orange : `#EF9F27` (prime)
- Coral : `#D85A30` (accent)

## Utilisation dans les Composants

### Importer le hook
```javascript
import { useTheme } from '../contexts/ThemeContext'

function MyComponent() {
  const { isDark, toggleTheme } = useTheme()
  
  return (
    <button onClick={toggleTheme}>
      {isDark ? <Sun /> : <Moon />}
    </button>
  )
}
```

### Classes Tailwind Communes

| Élément | Mode Clair | Mode Sombre |
|---------|-----------|-------------|
| Titre H1 | `text-gray-900` | `dark:text-white` |
| Titre H2/H3 | `text-gray-900` | `dark:text-white` |
| Texte normal | `text-gray-600` | `dark:text-gray-400` |
| Texte léger | `text-gray-500` | `dark:text-gray-400` |
| Card | `bg-white` | `dark:bg-gray-800` |
| Background | `bg-gray-50` | `dark:bg-gray-900` |
| Input | `bg-gray-50` | `dark:bg-gray-700` |
| Hover card | `hover:bg-gray-50` | `dark:hover:bg-gray-700/50` |
| Bordure | `border-gray-100/30` | `dark:border-gray-700/30` |

## Débogage

### Vérifier l'état du thème
```javascript
// Dans la console du navigateur
localStorage.getItem('admin_theme') // 'light' ou 'dark'
document.documentElement.classList.contains('dark') // true ou false
```

### Logs de débogage
Le ThemeContext affiche des logs dans la console :
- Initial theme from localStorage
- Theme changed to: dark/light
- Dark/Light mode applied

### Problèmes Courants

**1. Le toggle ne fonctionne pas**
- Vérifiez que `ThemeProvider` entoure l'application dans `App.jsx`
- Vérifiez la console pour les erreurs
- Vérifiez que `darkMode: 'class'` est dans `tailwind.config.js`

**2. Les couleurs ne changent pas**
- Vérifiez que les classes `dark:` sont présentes dans les composants
- Vérifiez que Tailwind compile les variantes dark
- Rechargez la page après modification du config

**3. Flash de contenu au chargement**
- Vérifiez que le script inline est dans `index.html`
- Le script doit être dans `<head>` avant le CSS

## Ajout de Nouvelles Pages

Quand vous créez une nouvelle page, utilisez ces patterns :

```jsx
export default function NewPage() {
  return (
    <div className="space-y-6">
      {/* Titre */}
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
        Titre de la Page
      </h1>
      
      {/* Sous-titre */}
      <p className="text-gray-600 dark:text-gray-400">
        Description
      </p>
      
      {/* Card */}
      <div className="card p-6">
        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
          Section
        </h3>
        <p className="text-sm text-gray-600 dark:text-gray-400">
          Contenu
        </p>
      </div>
      
      {/* Input */}
      <input 
        className="input"
        placeholder="Texte..."
      />
      
      {/* Badge */}
      <span className="badge badge-success">
        Statut
      </span>
    </div>
  )
}
```

## Performance

- Le toggle est instantané (pas d'animation)
- Pas de re-render inutile grâce au Context
- localStorage est synchrone et rapide
- Les classes Tailwind sont purgées en production

## Accessibilité

- Respecte la préférence système de l'utilisateur
- Contraste suffisant dans les deux modes
- Bouton toggle accessible au clavier
- Labels clairs ("Mode clair" / "Mode sombre")
