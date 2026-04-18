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
from app.models.booking import Base

# Import des routes
from app.api.routes import bookings, health

# ============================================================================
# CRÉER L'APPLICATION FASTAPI
# ============================================================================

# Créer une instance de l'application FastAPI
app = FastAPI(
    # Titre de l'API
    title="Booking Service API",
    
    # Description détaillée
    description="""
    Service de réservation pour l'application COVOIT.
    Gère:
    - Création de réservations de trajets
    - Vérification et recherche de réservations
    - Confirmation après paiement
    - Annulation et gestion des no-shows
    - Historique et statistiques de réservation
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

# Inclure le routeur des réservations avec un préfixe /bookings
app.include_router(bookings.router)

# Inclure le routeur de santé
app.include_router(health.router)

# ============================================================================
# ÉVÉNEMENTS DE DÉMARRAGE ET ARRÊT
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """
    Événement exécuté au démarrage de l'application.
    """
    
    # Afficher un message de démarrage
    print("=" * 80)
    print("BOOKING SERVICE DÉMARRÉ")
    print("=" * 80)
    print(f"Mode DEBUG: {settings.DEBUG}")
    print(f"Base de données: {settings.DATABASE_URL}")
    print("Routes disponibles:")
    print("  - POST   /bookings          (Créer une réservation)")
    print("  - GET    /bookings/{id}     (Récupérer une réservation)")
    print("  - GET    /bookings/passenger/{id}  (Réservations du passager)")
    print("  - GET    /bookings/trip/{id}       (Réservations du trajet)")
    print("  - POST   /bookings/search   (Rechercher des réservations)")
    print("  - PUT    /bookings/{id}     (Mettre à jour)")
    print("  - POST   /bookings/{id}/confirm   (Confirmer après paiement)")
    print("  - POST   /bookings/{id}/cancel    (Annuler)")
    print("  - POST   /bookings/{id}/complete  (Marquer complété)")
    print("  - POST   /bookings/{id}/no-show   (Marquer no-show)")
    print("  - POST   /bookings/{id}/notes     (Ajouter une note)")
    print("  - GET    /bookings/{id}/notes     (Récupérer les notes)")
    print("  - GET    /bookings/stats/passenger/{id}  (Statistiques)")
    print("  - GET    /health            (Santé du service)")
    print("=" * 80)

@app.on_event("shutdown")
async def shutdown_event():
    """
    Événement exécuté à l'arrêt de l'application.
    """
    
    # Afficher un message d'arrêt
    print("=" * 80)
    print("BOOKING SERVICE ARRÊTÉ")
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
        "message": "Bienvenue dans le Booking Service de COVOIT",
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
    
    # Lancer l'application sur le port 8004 (réservé au Booking Service)
    uvicorn.run(
        app,
        host="0.0.0.0",     # Écouter sur toutes les interfaces
        port=8004,          # Port du Booking Service
        reload=True         # Rechargement automatique en développement
    )
