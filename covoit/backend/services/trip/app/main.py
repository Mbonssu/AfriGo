# Import FastAPI pour créer l'application web
from fastapi import FastAPI

# Import CORS pour autoriser les requêtes cross-origin (du frontend)
from fastapi.middleware.cors import CORSMiddleware

# Import de la configuration
from app.core.config import settings

# Import des modèles SQLAlchemy pour créer les tables
from app.models.trip import Base

# Import du moteur et session database
from app.db.session import engine

# Import des routeurs (routes d'endpoints)
from app.api.routes import trips, health

# Import logging
import logging

# Configurer les logs
logging.basicConfig(
    # Format des logs: timestamp - nom du module - niveau - message
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    # Niveau minimum: INFO (inclut WARNING, ERROR, CRITICAL)
    level=logging.INFO
)

# Créer une instance du logger pour ce module
logger = logging.getLogger(__name__)

# =====================================================
# CRÉATION DE L'APPLICATION FASTAPI
# =====================================================

# Créer l'application FastAPI avec infos pour la doc
app = FastAPI(
    # Titre de l'API (affiché dans la doc Swagger)
    title=settings.SERVICE_TITLE,
    # Description complète
    description=settings.SERVICE_DESCRIPTION,
    # Version de l'API
    version=settings.SERVICE_VERSION,
    # Documentation automatique disponible à /docs (Swagger UI)
    # et /redoc (ReDoc)
)

# =====================================================
# CONFIGURATION CORS (Cross-Origin Resource Sharing)
# =====================================================

# Ajouter middleware CORS pour autoriser les requêtes du frontend
# CORS permet au frontend (Flutter app) d'appeler cette API depuis un domaine différent
app.add_middleware(
    # Classe du middleware CORS
    CORSMiddleware,
    # Origines autorisées à accéder à l'API
    # "*" = toutes les origines (seulement pour développement!)
    # En production: spécifier les domaines autorisés
    allow_origins=["*"],
    # Méthodes HTTP autorisées
    allow_methods=["*"],  # GET, POST, PATCH, DELETE, etc
    # Headers autorisés dans les requêtes
    allow_headers=["*"],  # Content-Type, Authorization, etc
)

# =====================================================
# CRÉATION DES TABLES SQLALCHEMY
# =====================================================

# Créer toutes les tables définies dans les modèles
# Équivalent à: CREATE TABLE IF NOT EXISTS ...
Base.metadata.create_all(
    # Moteur de base de données à utiliser
    bind=engine
)

logger.info("Tables de base de données créées/vérifiées")

# =====================================================
# ENREGISTREMENT DES ROUTEURS
# =====================================================

# Inclure le routeur des trajets
# Cela enregistre toutes les routes: /trips/, /trips/{id}, /trips/search, etc
app.include_router(
    router=trips.router,
    # Préfixe optionnel (les routes commencent déjà par /trips)
    prefix=""
)

logger.info("Routes /trips enregistrées")

# Inclure le routeur de santé
# Cela enregistre la route: /health
app.include_router(
    router=health.router,
    # Préfixe optionnel (la route commence déjà par /health)
    prefix=""
)

logger.info("Routes /health enregistrées")

# =====================================================
# ÉVÉNEMENTS D'INITIALISATION ET ARRÊT
# =====================================================

@app.on_event("startup")
async def startup():
    """
    Événement appelé au démarrage de l'application.
    Utile pour initialiser les ressources (connexions DB, caches, etc).
    """
    logger.info("=" * 50)
    logger.info(f"Démarrage du {settings.SERVICE_TITLE}")
    logger.info(f"Version: {settings.SERVICE_VERSION}")
    logger.info(f"Mode DEBUG: {settings.DEBUG}")
    logger.info(f"Base de données: {settings.DATABASE_URL}")
    logger.info("=" * 50)


@app.on_event("shutdown")
async def shutdown():
    """
    Événement appelé à l'arrêt de l'application.
    Utilisé pour nettoyer les ressources (fermer connexions, etc).
    """
    logger.info("Arrêt du Trip Service")


# =====================================================
# ENDPOINTS RACINE
# =====================================================

@app.get("/")
async def root():
    """
    Endpoint racine de l'API.
    Retourne un message de bienvenue.
    """
    return {
        # Message de bienvenue
        "message": "Bienvenue sur le Trip Service",
        # Nom du service
        "service": settings.SERVICE_TITLE,
        # Version
        "version": settings.SERVICE_VERSION,
        # Documentation disponible à /docs
        "docs": "/docs",
        # Documentation alternative à /redoc
        "redoc": "/redoc",
        # Endpoint de santé
        "health": "/health"
    }


# =====================================================
# CONFIGURATION POUR PRODUCTION
# =====================================================

# Remarques pour déploiement:
# - Cette app est prévue pour tourner sur uvicorn (serveur ASGI)
# - Commande de démarrage: uvicorn app.main:app --host 0.0.0.0 --port 8003
# - En production, utiliser gunicorn + uvicorn workers:
#   gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8003
