from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "Covoit Tracking Service"
    DEBUG: bool = False
    DATABASE_URL: str = "postgresql://covoit:covoit_secret@postgres:5432/tracking_db"
    REDIS_HOST: str = "redis"
    REDIS_PORT: int = 6379

    class Config:
        env_file = ".env"


settings = Settings()
