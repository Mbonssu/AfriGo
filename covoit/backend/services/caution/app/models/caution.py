from sqlalchemy import Column, String, DateTime, Integer, Enum as SAEnum
from sqlalchemy.orm import declarative_base
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from datetime import datetime

Base = declarative_base()


class CautionStatus(str, enum.Enum):
    pending = "pending"
    refunded = "refunded"
    retained = "retained"


class CautionType(str, enum.Enum):
    passenger = "passenger"
    driver = "driver"


class Caution(Base):
    __tablename__ = "cautions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    booking_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    trip_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    trip_route = Column(String(200), nullable=False)
    amount = Column(Integer, nullable=False, default=500)  # en FCFA
    caution_type = Column(SAEnum(CautionType), nullable=False)
    status = Column(SAEnum(CautionStatus), default=CautionStatus.pending)
    reason = Column(String(300), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
