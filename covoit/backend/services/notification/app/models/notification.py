from sqlalchemy import Column, String, DateTime, Boolean, Text
from sqlalchemy.orm import declarative_base
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime

Base = declarative_base()


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    icon = Column(String(50), default="info")  # info, trip, booking, payment, promo, rating
    is_read = Column(Boolean, default=False)
    action_type = Column(String(50), nullable=True)  # open_trip, open_booking, open_chat
    action_id = Column(String(100), nullable=True)  # ID de la ressource liée
    created_at = Column(DateTime, default=datetime.utcnow)
