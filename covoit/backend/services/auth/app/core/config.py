from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "AfriGo Auth Service"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/auth_db"
    
    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production-auth-service"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Redis - Pour la blacklist des tokens
    REDIS_HOST: str = "localhost"  # En Docker: "redis" (nom du service)
    REDIS_PORT: int = 6379         # Port standard de Redis
    
    class Config:
        env_file = ".env"

settings = Settings()
