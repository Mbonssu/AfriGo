# Import du framework FastAPI
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import de SQLAlchemy pour créer les tables
from sqlalchemy import event

# Import de la configuration
from app.core.config import settings

# Import de la session SQLAlchemy
from app.db.session import engine

# Import des modèles pour créer les tables
from app.models.payment import Base

# Import des routes
from app.api.routes import payments, health

# ============================================================================
# CRÉER L'APPLICATION FASTAPI
# ============================================================================

# Créer une instance de l'application FastAPI
app = FastAPI(
    # Titre de l'API
    title="Payment Service API",
    
    # Description détaillée
    description="""
    Service de paiement pour l'application COVOIT.
    Gère:
    - Création de paiements MTN/Orange Money
    - Vérification du statut des paiements
    - Remboursement et annulation
    - Statistiques et historique
    """,
    
    # Version de l'API
    version="1.0.0",
    
    # Contact du développeur
    contact={
        "name": "Support COVOIT",
        "email": "support@covoit.cm",
    },
)

# ============================================================================
# CONFIGURER LE CORS (Cross-Origin Resource Sharing)
# ============================================================================

# Ajouter les middlewares CORS pour accepter les requêtes cross-origin
app.add_middleware(
    # Classe du middleware
    CORSMiddleware,
    
    # Origines autorisées (domaines qui peuvent faire des requêtes)
    allow_origins=[
        "http://localhost:3000",      # Frontend en développement
        "http://localhost:8000",      # API Gateway en développement
        "http://api-gateway:8000",    # API Gateway en Docker
        "*",                          # Temporairement tout autoriser (à restreindre en prod)
    ],
    
    # Méthodes HTTP autorisées
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    
    # Headers autorisés
    allow_headers=["*"],
    
    # Credentials (cookies, auth) autorisés
    allow_credentials=True,
)

# ============================================================================
# CRÉER LES TABLES EN BASE DE DONNÉES
# ============================================================================

# Créer toutes les tables définies dans les modèles
# Cette ligne exécute les CREATE TABLE si elles n'existent pas
Base.metadata.create_all(bind=engine)

# ============================================================================
# ENREGISTRER LES ROUTES
# ============================================================================

# Inclure le routeur des paiements avec un préfixe /payments
# Les endpoints seront accessibles à : /payments, /payments/{id}, etc.
app.include_router(payments.router)

# Inclure le routeur de santé
# L'endpoint /health sera accessible à : /health
app.include_router(health.router)

# ============================================================================
# ÉVÉNEMENTS DE DÉMARRAGE ET ARRÊT
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """
    Événement exécuté au démarrage de l'application.
    
    Actions:
    1. Afficher un message de démarrage
    2. Initialiser les connexions de base de données
    3. Charger les configurations
    """
    
    # Afficher un message de démarrage
    print("=" * 80)
    print("PAYMENT SERVICE DÉMARRÉ")
    print("=" * 80)
    print(f"Mode DEBUG: {settings.DEBUG}")
    print(f"Base de données: {settings.DATABASE_URL}")
    print("Routes disponibles:")
    print("  - POST   /payments          (Créer un paiement)")
    print("  - GET    /payments/{id}     (Récupérer un paiement)")
    print("  - GET    /payments/user/{user_id}  (Paiements d'un utilisateur)")
    print("  - POST   /payments/search   (Rechercher des paiements)")
    print("  - PUT    /payments/{id}/status     (Mettre à jour le statut)")
    print("  - POST   /payments/{id}/cancel     (Annuler un paiement)")
    print("  - POST   /payments/{id}/refund     (Rembourser un paiement)")
    print("  - GET    /payments/stats/user/{user_id}  (Statistiques)")
    print("  - GET    /health            (Santé du service)")
    print("=" * 80)

@app.on_event("shutdown")
async def shutdown_event():
    """
    Événement exécuté à l'arrêt de l'application.
    
    Actions:
    1. Fermer les connexions
    2. Sauvegarder les données
    3. Afficher un message d'arrêt
    """
    
    # Afficher un message d'arrêt
    print("=" * 80)
    print("PAYMENT SERVICE ARRÊTÉ")
    print("=" * 80)

# ============================================================================
# ENDPOINT RACINE
# ============================================================================

@app.get(
    "/",
    summary="Information sur l'API",
    tags=["Info"]
)
def read_root():
    """
    Endpoint racine qui retourne des informations sur l'API.
    
    Retour:
        dict: Information de bienvenue et lien vers la documentation
    """
    
    return {
        "message": "Bienvenue dans le Payment Service de COVOIT",
        "version": "1.0.0",
        "documentation": "/docs",
        "status": "operational"
    }

# ============================================================================
# SI LE FICHIER EST EXÉCUTÉ DIRECTEMENT
# ============================================================================

if __name__ == "__main__":
    # Importer uvicorn pour lancer le serveur
    import uvicorn
    
    # Lancer l'application sur le port 8006 (réservé au Payment Service)
    # reload=True permettra le rechargement automatique lors des modifications
    uvicorn.run(
        app,
        host="0.0.0.0",     # Écouter sur toutes les interfaces
        port=8006,          # Port du Payment Service
        reload=True         # Rechargement automatique en développement
    )
