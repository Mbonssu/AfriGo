from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Covoit API Gateway"
    DEBUG: bool = False
    
    # Services URLs - URL complètes des services microservices
    # Chaque service écoute sur un port différent
    # Ces URLs sont utilisées pour forwarder les requêtes vers les services appropriés
    AUTH_SERVICE_URL: str = "http://localhost:8001"  # Service d'authentification
    USER_SERVICE_URL: str = "http://localhost:8002"  # Service utilisateurs (profils)
    TRIP_SERVICE_URL: str = "http://localhost:8003"  # Service trajets
    BOOKING_SERVICE_URL: str = "http://localhost:8004"  # Service réservations (nouveau)
    PAYMENT_SERVICE_URL: str = "http://localhost:8006"  # Service paiements
    NOTIFICATION_SERVICE_URL: str = "http://localhost:8005"  # Service notifications
    CHAT_SERVICE_URL: str = "http://localhost:8007"  # Service messagerie
    SUBSCRIPTION_SERVICE_URL: str = "http://localhost:8008"  # Service abonnement Prime
    CAUTION_SERVICE_URL: str = "http://localhost:8009"  # Service cautions
    FORUM_SERVICE_URL: str = "http://localhost:8010"  # Forum Prime
    TRACKING_SERVICE_URL: str = "http://localhost:8011"  # Service suivi GPS
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Redis - Pour la blacklist des tokens
    REDIS_HOST: str = "localhost"  # En Docker: "redis" (nom du service)
    REDIS_PORT: int = 6379         # Port standard de Redis
    
    class Config:
        env_file = ".env"

settings = Settings()
