import re
from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from typing import Any, List, Optional


CM_PHONE_REGEX = re.compile(r"^(?:\+?237)?[6-9]\d{8}$")
NAME_REGEX = re.compile(r"^[a-zA-ZÀ-ÿ\s\-']+$")
PLATE_REGEX = re.compile(r"^[A-Za-z]{2}\d{3,5}[A-Za-z]{0,2}$")

class UserProfileBase(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    bio: Optional[str] = None

class UserProfileUpdate(UserProfileBase):
    phone: Optional[str] = None
    profile_picture_url: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

    @field_validator("first_name", "last_name", "emergency_contact_name")
    @classmethod
    def validate_name_fields(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = v.strip()
        if not cleaned:
            return None
        if len(cleaned) < 2 or len(cleaned) > 60:
            raise ValueError("Nom invalide (2 a 60 caracteres)")
        if not NAME_REGEX.match(cleaned):
            raise ValueError("Nom invalide")
        return cleaned

    @field_validator("phone", "emergency_contact_phone")
    @classmethod
    def validate_phone_fields(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = re.sub(r"[\s\-\(\)]", "", v)
        if not CM_PHONE_REGEX.match(cleaned):
            raise ValueError("Telephone invalide (format Cameroun attendu)")
        return cleaned

class UserProfileResponse(UserProfileBase):
    id: Any
    user_id: Any
    phone: str
    profile_picture_url: Optional[str] = None
    rating: float
    total_reviews: Any
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    kyc_status: Optional[str] = "none"
    cni_type: Optional[str] = None
    cni_number: Optional[str] = None
    cni_photo_url: Optional[str] = None
    selfie_url: Optional[str] = None
    license_photo_url: Optional[str] = None
    registration_card_url: Optional[str] = None
    face_match_score: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    @field_validator('id', 'user_id', 'total_reviews', mode='before')
    @classmethod
    def to_str(cls, v: Any) -> str:
        return str(v) if v is not None else ''

    class Config:
        from_attributes = True

class DriverProfileBase(BaseModel):
    license_number: Optional[str] = ''
    vehicle_model: Optional[str] = ''
    vehicle_plate: Optional[str] = ''
    is_prime: Optional[str] = "false"

class DriverProfileUpdate(DriverProfileBase):
    pass

class DriverProfileResponse(DriverProfileBase):
    id: Any
    user_id: Any
    total_trips: Any
    total_earnings: float
    rating: float
    created_at: datetime
    updated_at: datetime

    @field_validator('id', 'user_id', 'total_trips', mode='before')
    @classmethod
    def to_str(cls, v: Any) -> str:
        return str(v) if v is not None else ''

    class Config:
        from_attributes = True

class FullUserResponse(BaseModel):
    user_id: str
    profile: UserProfileResponse
    driver_profile: Optional[DriverProfileResponse] = None


# ── Vehicle schemas ──────────────────────────────────────────────────────────

class VehiclePhotoResponse(BaseModel):
    id: Any
    photo_url: str
    position: int
    ai_analysis: Optional[dict[str, Any]] = None

    @field_validator('id', mode='before')
    @classmethod
    def to_str(cls, v: Any) -> str:
        return str(v) if v is not None else ''

    class Config:
        from_attributes = True


class VehicleCreate(BaseModel):
    brand: str = Field(..., min_length=2, max_length=50)
    model: str = Field(..., min_length=1, max_length=50)
    year: Optional[int] = None
    color: Optional[str] = Field(default=None, max_length=30)
    plate: str = Field(..., min_length=5, max_length=20)
    seats: int = Field(default=4, ge=2, le=9)

    @field_validator("year")
    @classmethod
    def validate_year(cls, v: Optional[int]) -> Optional[int]:
        if v is None:
            return v
        current_year = datetime.utcnow().year
        if v < 2005 or v > current_year + 1:
            raise ValueError("Annee invalide")
        return v

    @field_validator("plate")
    @classmethod
    def validate_plate(cls, v: str) -> str:
        cleaned = re.sub(r"\s+", "", v)
        if not PLATE_REGEX.match(cleaned):
            raise ValueError("Format de plaque invalide")
        return cleaned.upper()


class VehicleUpdate(BaseModel):
    brand: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    color: Optional[str] = None
    plate: Optional[str] = None
    seats: Optional[int] = None

    @field_validator("brand")
    @classmethod
    def validate_brand(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = v.strip()
        if len(cleaned) < 2 or len(cleaned) > 50:
            raise ValueError("Marque invalide")
        return cleaned

    @field_validator("model")
    @classmethod
    def validate_model(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = v.strip()
        if len(cleaned) < 1 or len(cleaned) > 50:
            raise ValueError("Modele invalide")
        return cleaned

    @field_validator("year")
    @classmethod
    def validate_update_year(cls, v: Optional[int]) -> Optional[int]:
        if v is None:
            return v
        current_year = datetime.utcnow().year
        if v < 2005 or v > current_year + 1:
            raise ValueError("Annee invalide")
        return v

    @field_validator("plate")
    @classmethod
    def validate_update_plate(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = re.sub(r"\s+", "", v)
        if not PLATE_REGEX.match(cleaned):
            raise ValueError("Format de plaque invalide")
        return cleaned.upper()

    @field_validator("seats")
    @classmethod
    def validate_update_seats(cls, v: Optional[int]) -> Optional[int]:
        if v is None:
            return v
        if v < 2 or v > 9:
            raise ValueError("Le nombre de places doit etre entre 2 et 9")
        return v


class VehicleResponse(BaseModel):
    id: Any
    user_id: Any
    brand: str
    model: str
    year: Optional[int] = None
    color: Optional[str] = None
    plate: str
    seats: int
    photos: List[VehiclePhotoResponse] = []
    created_at: datetime
    updated_at: datetime

    @field_validator('id', 'user_id', mode='before')
    @classmethod
    def to_str(cls, v: Any) -> str:
        return str(v) if v is not None else ''

    class Config:
        from_attributes = True
