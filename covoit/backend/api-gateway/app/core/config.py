from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # App
    APP_NAME: str = "AfriGo API Gateway"
    DEBUG: bool = False
    
    # Services URLs - URL complètes des services microservices
    # En Docker Compose, les services communiquent via leurs noms de service
    # Le réseau Docker interne permet la résolution DNS automatique
    AUTH_SERVICE_URL: str = "http://auth-service:8000"  # Service d'authentification
    USER_SERVICE_URL: str = "http://user-service:8000"  # Service utilisateurs (profils)
    TRIP_SERVICE_URL: str = "http://trip-service:8000"  # Service trajets
    BOOKING_SERVICE_URL: str = "http://booking-service:8000"  # Service réservations
    PAYMENT_SERVICE_URL: str = "http://payment-service:8000"  # Service paiements
    NOTIFICATION_SERVICE_URL: str = "http://notification-service:8000"  # Service notifications
    CHAT_SERVICE_URL: str = "http://chat-service:8000"  # Service messagerie
    SUBSCRIPTION_SERVICE_URL: str = "http://subscription-service:8000"  # Service abonnement Prime
    CAUTION_SERVICE_URL: str = "http://caution-service:8000"  # Service cautions
    FORUM_SERVICE_URL: str = "http://forum-service:8000"  # Forum Prime
    TRACKING_SERVICE_URL: str = "http://tracking-service:8000"  # Service suivi GPS
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Redis - Pour la blacklist des tokens
    # En Docker: utiliser le nom du service "redis"
    REDIS_HOST: str = "redis"  # Nom du service Docker
    REDIS_PORT: int = 6379     # Port standard de Redis
    
    class Config:
        env_file = ".env"

settings = Settings()
