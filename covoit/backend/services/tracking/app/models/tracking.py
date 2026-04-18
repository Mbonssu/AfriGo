from sqlalchemy import Column, String, DateTime, Float, Enum as SAEnum
from sqlalchemy.orm import declarative_base
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from datetime import datetime

Base = declarative_base()


class TripTrackingStatus(str, enum.Enum):
    not_started = "not_started"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class TripTracking(Base):
    __tablename__ = "trip_trackings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    driver_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    status = Column(SAEnum(TripTrackingStatus), default=TripTrackingStatus.not_started)
    current_lat = Column(Float, nullable=True)
    current_lng = Column(Float, nullable=True)
    progress = Column(Float, default=0.0)  # 0.0 → 1.0
    current_step = Column(String(200), nullable=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)


class TripStep(Base):
    __tablename__ = "trip_steps"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    label = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    estimated_time = Column(String(20), nullable=True)
    actual_time = Column(String(20), nullable=True)
    status = Column(String(20), default="pending")  # done, current, pending
    order_index = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
