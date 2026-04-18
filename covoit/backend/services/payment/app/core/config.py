# Import de BaseSettings depuis pydantic pour gérer les variables d'environnement
from pydantic_settings import BaseSettings

# Import de Field depuis pydantic pour ajouter des descriptions et valeurs par défaut
from pydantic import Field

# Classe de configuration qui gère toutes les variables d'environnement du service
class Settings(BaseSettings):
    # Mode DEBUG - défini sur False en production
    DEBUG: bool = Field(default=False, description="Mode debug de l'application")
    
    # URL complète de la base de données PostgreSQL pour ce service
    # Format: postgresql://user:password@host:port/dbname
    DATABASE_URL: str = Field(
        default="postgresql://postgres:postgres@postgres-payment:5435/payment_db",
        description="URL de connexion PostgreSQL pour la base payment_db"
    )
    
    # Clé secrète utilisée pour signer les JWT et autres opérations cryptographiques
    # À CHANGER en production avec une valeur aléatoire longue et sécurisée
    SECRET_KEY: str = Field(
        default="your-secret-key-payment-service-change-in-production",
        description="Clé secrète pour la signature JWT et opérations cryptographiques"
    )
    
    # Titre du service pour la documentation Swagger
    SERVICE_TITLE: str = "Payment Service"
    
    # Description du service pour la documentation Swagger
    SERVICE_DESCRIPTION: str = "Service de gestion des paiements - MTN, Orange Money, cautions"
    
    # Version de l'API
    SERVICE_VERSION: str = "1.0.0"

    # Monetbil
    MONETBIL_API_BASE_URL: str = Field(
        default="https://api.monetbil.com/payment/v1",
        description="Base URL de l'API Monetbil Collections v1",
    )
    MONETBIL_SERVICE_KEY: str = Field(
        default="",
        description="Clé de service Monetbil récupérée depuis le dashboard",
    )
    MONETBIL_NOTIFY_URL: str = Field(
        default="",
        description="URL publique appelée par Monetbil pour les notifications serveur",
    )
    MONETBIL_RETURN_URL: str = Field(
        default="",
        description="URL de retour optionnelle après paiement Monetbil",
    )
    MONETBIL_COUNTRY: str = Field(
        default="CM",
        description="Code pays ISO 3166-1 utilisé pour Monetbil",
    )
    MONETBIL_CURRENCY: str = Field(
        default="XAF",
        description="Devise utilisée pour Monetbil",
    )
    
    # Configuration pour Pydantic : lire les variables depuis les fichiers .env
    class Config:
        # Chercher un fichier .env à la racine du projet
        env_file = ".env"
        # Les noms des variables sont case-insensitive
        case_sensitive = False

# Créer une instance globale des paramètres de configuration
# Cette instance est utilisée partout dans l'application
settings = Settings()
