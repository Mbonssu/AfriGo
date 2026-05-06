import re
from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional


CM_PHONE_REGEX = re.compile(r"^(?:\+?237)?[6-9]\d{8}$")
STRONG_PASSWORD_REGEX = re.compile(r"^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?\":{}|<>\-_]).{8,}$")

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=128)

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    phone: str = Field(..., min_length=9, max_length=20)
    role: str = "passenger"

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, value: str) -> str:
        if not STRONG_PASSWORD_REGEX.match(value):
            raise ValueError(
                "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial."
            )
        return value

    @field_validator("phone")
    @classmethod
    def validate_phone_format(cls, value: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", value)
        if not CM_PHONE_REGEX.match(cleaned):
            raise ValueError("Numéro de téléphone invalide (format Cameroun attendu)")
        return cleaned

    @field_validator("role")
    @classmethod
    def normalize_role(cls, value: str) -> str:
        normalized = value.strip().lower()
        mapping = {
            "passager": "passenger",
            "passenger": "passenger",
            "chauffeur": "driver",
            "driver": "driver",
            "prime": "driver",
        }
        if normalized not in mapping:
            raise ValueError("Role invalide")
        return mapping[normalized]

class UserResponse(BaseModel):
    id: str
    email: str
    phone: str
    role: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    user: UserResponse

class AuthResponse(BaseModel):
    message: str
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def validate_password_strength(cls, value: str) -> str:
        if not STRONG_PASSWORD_REGEX.match(value):
            raise ValueError(
                "Le mot de passe doit contenir au moins 8 caractères, 1 majuscule, 1 chiffre et 1 caractère spécial."
            )
        return value

class MessageResponse(BaseModel):
    message: str
