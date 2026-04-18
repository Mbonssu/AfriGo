# Import de create_engine pour créer la connexion à la base PostgreSQL
from sqlalchemy import create_engine

# Import des sessionmaker et Session pour gérer les sessions de base de données
from sqlalchemy.orm import sessionmaker, Session

# Import de la configuration
from app.core.config import settings

# Créer le moteur SQLAlchemy qui gère la connexion à PostgreSQL
# echo=True affiche les requêtes SQL générées (utile pour debug)
# pool_size: nombre de connexions à maintenir dans le pool
# max_overflow: connexions supplémentaires autorisées au-delà du pool_size
engine = create_engine(
    # URL de connexion depuis les variables d'environnement
    settings.DATABASE_URL,
    # Afficher les requêtes SQL en console (only in DEBUG mode)
    echo=settings.DEBUG,
    # Gestion du pool de connexions
    pool_size=10,  # Nombre de connexions par défaut dans le pool
    max_overflow=20,  # Connexions extra si le pool est saturé
    # Pool de connexions expirées après 3600 secondes
    pool_recycle=3600
)

# Créer une factory de sessions qui sera utilisée pour créer de nouvelles sessions
# expire_on_commit=False: garder les objets valides après la validation
SessionLocal = sessionmaker(
    # Utiliser le moteur créé ci-dessus
    bind=engine,
    # Classe à utiliser pour les sessions
    class_=Session,
    # Ne pas expirer les objets après un commit
    expire_on_commit=False
)

# Fonction qui retourne une session de base de données
# Utilisée typiquement avec FastAPI en tant que dépendance
def get_db():
    """
    Dépendance FastAPI qui fournit une session de base de données.
    La session est automatiquement fermée après l'utilisation.
    
    Yields:
        Session: Une session SQLAlchemy pour les opérations de base de données
    """
    # Créer une nouvelle session
    db = SessionLocal()
    try:
        # Fournir la session à la route qui l'a demandée
        yield db
    finally:
        # Fermer la session (rollback automatique si erreur)
        db.close()
