from sqlalchemy import Column, String, DateTime, Integer, Boolean, Enum as SAEnum
from sqlalchemy.orm import declarative_base
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from datetime import datetime


Base = declarative_base()


class PlanType(str, enum.Enum):
    monthly = "monthly"
    quarterly = "quarterly"
    yearly = "yearly"


class SubscriptionStatus(str, enum.Enum):
    active = "active"
    expired = "expired"
    cancelled = "cancelled"
    pending = "pending"


class Plan(Base):
    __tablename__ = "plans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), nullable=False)
    plan_type = Column(SAEnum(PlanType), nullable=False, unique=True)
    price = Column(Integer, nullable=False)  # en FCFA
    duration_days = Column(Integer, nullable=False)
    description = Column(String(200), nullable=True)
    savings = Column(String(100), nullable=True)
    is_highlighted = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    plan_type = Column(SAEnum(PlanType), nullable=False)
    status = Column(SAEnum(SubscriptionStatus), default=SubscriptionStatus.pending)
    amount_paid = Column(Integer, nullable=False)
    payment_reference = Column(String(100), nullable=True)
    started_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    cancelled_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
