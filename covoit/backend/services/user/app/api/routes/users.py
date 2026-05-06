from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional
from app.schemas.user import UserProfileResponse, DriverProfileResponse, UserProfileUpdate, DriverProfileUpdate
from app.services.user_service import UserService, DriverService
from app.services.file_service import file_service
from app.db.session import get_db
import os
import uuid as uuid_mod
import logging
import re

logger = logging.getLogger(__name__)

UPLOAD_ROOT = os.getenv("UPLOAD_ROOT", "/app/uploads")
KYC_UPLOAD_DIR = os.path.join(UPLOAD_ROOT, "kyc")

router = APIRouter()

@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile(user_id: str, db: Session = Depends(get_db)):
    try:
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")
        return profile
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error getting user profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.patch("/{user_id}", response_model=UserProfileResponse)
async def update_user_profile(user_id: str, data: UserProfileUpdate, db: Session = Depends(get_db)):
    try:
        profile = UserService.update_profile(db, UUID(user_id), data)
        return profile
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error updating user profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.post("/{user_id}/profile-photo")
async def upload_profile_photo(
    user_id: str,
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload or update profile photo"""
    try:
        # Validate file type
        if photo.content_type not in ("image/jpeg", "image/png", "image/webp"):
            raise HTTPException(status_code=400, detail="Format invalide. Utilisez JPEG, PNG ou WebP")
        
        # Validate file size (max 5MB)
        content = await photo.read()
        if len(content) > 5 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Photo trop volumineuse (max 5 Mo)")
        
        # Reset file pointer
        await photo.seek(0)
        
        # Get user profile
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")
        
        # Delete old photo if exists
        if profile.profile_picture_url:
            file_service.delete_file(profile.profile_picture_url)
        
        # Save new photo
        photo_url = await file_service.save_profile_photo(user_id, photo)
        
        # Update profile
        update_data = UserProfileUpdate(profile_picture_url=photo_url)
        profile = UserService.update_profile(db, UUID(user_id), update_data)
        
        return {
            "message": "Photo de profil mise à jour avec succès",
            "photo_url": photo_url
        }
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading profile photo: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.put("/{user_id}/profile")
async def update_profile_with_photo(
    user_id: str,
    first_name: Optional[str] = Form(None),
    last_name: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
):
    """Update profile information with optional photo upload"""
    try:
        # Get user profile
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")
        
        # Handle photo upload if provided
        photo_url = None
        if photo:
            # Validate file type
            if photo.content_type not in ("image/jpeg", "image/png", "image/webp"):
                raise HTTPException(status_code=400, detail="Format invalide. Utilisez JPEG, PNG ou WebP")
            
            # Validate file size (max 5MB)
            content = await photo.read()
            if len(content) > 5 * 1024 * 1024:
                raise HTTPException(status_code=400, detail="Photo trop volumineuse (max 5 Mo)")
            
            # Reset file pointer
            await photo.seek(0)
            
            # Delete old photo if exists
            if profile.profile_picture_url:
                file_service.delete_file(profile.profile_picture_url)
            
            # Save new photo
            photo_url = await file_service.save_profile_photo(user_id, photo)
        
        # Update profile data
        update_data = UserProfileUpdate(
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            profile_picture_url=photo_url if photo_url else None
        )
        
        profile = UserService.update_profile(db, UUID(user_id), update_data)
        
        return {
            "message": "Profil mis à jour avec succès",
            "profile": UserProfileResponse.model_validate(profile)
        }
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/{user_id}/driver", response_model=DriverProfileResponse)
async def create_driver_profile(user_id: str, data: DriverProfileUpdate, db: Session = Depends(get_db)):
    try:
        driver_profile = DriverService.create_driver_profile(db, UUID(user_id), data)
        return driver_profile
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error creating driver profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/{user_id}/driver", response_model=DriverProfileResponse)
async def get_driver_profile(user_id: str, db: Session = Depends(get_db)):
    try:
        driver_profile = DriverService.get_driver_profile(db, UUID(user_id))
        return driver_profile
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error getting driver profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


# ── Contact d'urgence ────────────────────────────────────────

from pydantic import BaseModel, Field, field_validator


CM_PHONE_REGEX = re.compile(r"^(?:\+?237)?[6-9]\d{8}$")
NAME_REGEX = re.compile(r"^[a-zA-ZÀ-ÿ\s\-']+$")

class EmergencyContactUpdate(BaseModel):
    emergency_contact_name: str = Field(..., min_length=2, max_length=60)
    emergency_contact_phone: str = Field(..., min_length=9, max_length=20)

    @field_validator("emergency_contact_name")
    @classmethod
    def validate_contact_name(cls, value: str) -> str:
        cleaned = value.strip()
        if not NAME_REGEX.match(cleaned):
            raise ValueError("Nom du contact invalide")
        return cleaned

    @field_validator("emergency_contact_phone")
    @classmethod
    def validate_contact_phone(cls, value: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", value)
        if not CM_PHONE_REGEX.match(cleaned):
            raise ValueError("Telephone du contact invalide")
        return cleaned

class EmergencyContactResponse(BaseModel):
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None

@router.get("/{user_id}/emergency-contact", response_model=EmergencyContactResponse)
async def get_emergency_contact(user_id: str, db: Session = Depends(get_db)):
    try:
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")
        return EmergencyContactResponse(
            emergency_contact_name=profile.emergency_contact_name,
            emergency_contact_phone=profile.emergency_contact_phone,
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")

@router.put("/{user_id}/emergency-contact", response_model=EmergencyContactResponse)
async def set_emergency_contact(user_id: str, data: EmergencyContactUpdate, db: Session = Depends(get_db)):
    try:
        from app.schemas.user import UserProfileUpdate
        update = UserProfileUpdate(
            emergency_contact_name=data.emergency_contact_name,
            emergency_contact_phone=data.emergency_contact_phone,
        )
        profile = UserService.update_profile(db, UUID(user_id), update)
        return EmergencyContactResponse(
            emergency_contact_name=profile.emergency_contact_name,
            emergency_contact_phone=profile.emergency_contact_phone,
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error setting emergency contact: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


# ── KYC — Vérification d'identité ────────────────────────────

class KYCStatusResponse(BaseModel):
    kyc_status: str
    cni_type: str | None = None
    cni_number: str | None = None
    face_match_score: float | None = None


@router.get("/{user_id}/kyc", response_model=KYCStatusResponse)
async def get_kyc_status(user_id: str, db: Session = Depends(get_db)):
    """Récupère le statut KYC de l'utilisateur."""
    try:
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")
        return KYCStatusResponse(
            kyc_status=profile.kyc_status or "none",
            cni_type=profile.cni_type,
            cni_number=profile.cni_number,
            face_match_score=profile.face_match_score,
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")


@router.post("/{user_id}/kyc/verify")
async def verify_identity(
    user_id: str,
    cni_photo: UploadFile = File(...),
    selfie: UploadFile = File(...),
    license_photo: Optional[UploadFile] = File(None),
    registration_card: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
):
    """
    Reçoit la CNI, le selfie, et optionnellement le permis et la carte grise,
    les stocke, et passe le statut KYC à 'pending' en attente d'une vérification manuelle.
    """
    try:
        profile = UserService.get_profile(db, UUID(user_id))
        if not profile:
            raise HTTPException(status_code=404, detail="User profile not found")

        # Validate all provided files
        files_to_validate = [cni_photo, selfie]
        if license_photo:
            files_to_validate.append(license_photo)
        if registration_card:
            files_to_validate.append(registration_card)
        
        for f in files_to_validate:
            if f.content_type not in ("image/jpeg", "image/png", "image/webp"):
                raise HTTPException(status_code=400, detail=f"Format invalide pour {f.filename}")
            
            content = await f.read()
            if len(content) > 10 * 1024 * 1024:
                raise HTTPException(status_code=400, detail=f"{f.filename} trop volumineux (max 10 Mo)")
            await f.seek(0)  # Reset file pointer

        # Save CNI photo
        cni_url = await file_service.save_cni_photo(user_id, cni_photo)
        profile.cni_photo_url = cni_url
        
        # Save selfie
        selfie_url = await file_service.save_selfie(user_id, selfie)
        profile.selfie_url = selfie_url
        
        # Save license photo if provided
        if license_photo:
            license_url = await file_service.save_license_photo(user_id, license_photo)
            profile.license_photo_url = license_url
        
        # Save registration card if provided
        if registration_card:
            registration_url = await file_service.save_registration_card(user_id, registration_card)
            profile.registration_card_url = registration_url

        profile.kyc_status = "pending"
        db.commit()
        db.refresh(profile)

        return {
            "kyc_status": "pending",
            "message": "Documents reçus. Votre identité sera vérifiée manuellement sous 24-48h.",
            "cni_photo_url": cni_url,
            "selfie_url": selfie_url,
            "license_photo_url": profile.license_photo_url,
            "registration_card_url": profile.registration_card_url,
        }

    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"KYC verification error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")
