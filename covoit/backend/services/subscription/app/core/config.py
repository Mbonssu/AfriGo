from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "Covoit Subscription Service"
    DEBUG: bool = False
    DATABASE_URL: str = "postgresql://covoit:covoit_secret@postgres:5432/subscription_db"

    class Config:
        env_file = ".env"


settings = Settings()
