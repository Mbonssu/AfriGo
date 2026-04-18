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
    Fonction de dépendance FastAPI pour obtenir une session de base de données.
    
    Flux:
    1. Créer une nouvelle session
    2. La yield à FastAPI pour l'injection de dépendance
    3. Fermer automatiquement la session après la requête
    
    Utilisation dans FastAPI:
    @app.get("/api/bookings")
    def list_bookings(db: Session = Depends(get_db)):
        return db.query(Booking).all()
    
    La session est automatiquement fermée par FastAPI après la requête.
    """
    
    # Créer une nouvelle session à partir de la factory
    db = SessionLocal()
    
    try:
        # Yield la session à FastAPI pour l'utiliser dans le endpoint
        yield db
    finally:
        # Fermer la session après la requête (même si une erreur s'est produite)
        db.close()
