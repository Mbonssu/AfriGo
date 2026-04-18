from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.core.config import settings
from app.models.subscription import Base, Plan, PlanType
import logging

logger = logging.getLogger(__name__)

engine = create_engine(settings.DATABASE_URL, echo=settings.DEBUG, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    Base.metadata.create_all(bind=engine)
    logger.info("Subscription tables created")


def seed_plans():
    """Insère les plans par défaut s'ils n'existent pas."""
    db = SessionLocal()
    try:
        if db.query(Plan).count() == 0:
            plans = [
                Plan(
                    name="Mensuel",
                    plan_type=PlanType.monthly,
                    price=5000,
                    duration_days=30,
                    description="Abonnement mensuel Prime",
                    savings=None,
                    is_highlighted=False,
                ),
                Plan(
                    name="Trimestriel",
                    plan_type=PlanType.quarterly,
                    price=12000,
                    duration_days=90,
                    description="Abonnement trimestriel Prime",
                    savings="Économisez 3 000 FCFA",
                    is_highlighted=False,
                ),
                Plan(
                    name="Annuel",
                    plan_type=PlanType.yearly,
                    price=40000,
                    duration_days=365,
                    description="Abonnement annuel Prime",
                    savings="Économisez 20 000 FCFA",
                    is_highlighted=True,
                ),
            ]
            db.add_all(plans)
            db.commit()
            logger.info("Default plans seeded")
    finally:
        db.close()
