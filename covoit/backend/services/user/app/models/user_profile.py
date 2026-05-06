from sqlalchemy import Column, String, DateTime, Float, Text, Enum, Integer, ForeignKey
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
import enum

Base = declarative_base()

class UserType(str, enum.Enum):
    PASSENGER = "passenger"
    DRIVER = "driver"

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, unique=True)  # FK from Auth Service
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    phone = Column(String, nullable=True, default='')
    profile_picture_url = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    rating = Column(Float, default=0.0)  # 1-5 stars, 0 = pas encore noté
    total_reviews = Column(String, default="0")
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    # KYC
    kyc_status = Column(String, default="none")  # none, pending, verified, rejected
    cni_type = Column(String, nullable=True)  # ancien, nouveau
    cni_number = Column(String, nullable=True)
    cni_photo_url = Column(String, nullable=True)
    selfie_url = Column(String, nullable=True)
    face_match_score = Column(Float, nullable=True)
    license_photo_url = Column(String, nullable=True)  # Driver license photo
    registration_card_url = Column(String, nullable=True)  # Vehicle registration card (carte grise)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<UserProfile {self.user_id}>"

class DriverProfile(Base):
    __tablename__ = "driver_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, unique=True)  # FK from Auth Service
    license_number = Column(String, nullable=True, default='')
    vehicle_model = Column(String, nullable=True, default='')
    vehicle_plate = Column(String, nullable=True, default='')
    is_prime = Column(String, default="false")  # Premium driver
    total_trips = Column(String, default="0")
    total_earnings = Column(Float, default=0.0)
    rating = Column(Float, default=0.0)  # 0 = pas encore noté
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<DriverProfile {self.user_id}>"


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    brand = Column(String(100), nullable=False)
    model = Column(String(100), nullable=False)
    year = Column(Integer, nullable=True)
    color = Column(String(50), nullable=True)
    plate = Column(String(20), nullable=False)
    seats = Column(Integer, nullable=False, default=4)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    photos = relationship("VehiclePhoto", back_populates="vehicle", cascade="all, delete-orphan", lazy="joined")

    def __repr__(self):
        return f"<Vehicle {self.brand} {self.model} ({self.plate})>"


class VehiclePhoto(Base):
    __tablename__ = "vehicle_photos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False, index=True)
    photo_url = Column(String, nullable=False)
    position = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    vehicle = relationship("Vehicle", back_populates="photos")

    def __repr__(self):
        return f"<VehiclePhoto {self.vehicle_id} pos={self.position}>"
