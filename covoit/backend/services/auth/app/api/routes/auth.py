from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.auth import (
    LoginRequest, 
    RegisterRequest, 
    TokenResponse, 
    AuthResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    MessageResponse
)
from app.services.auth_service import AuthService
from app.db.session import get_db
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


def _role_value(role) -> str:
    return role.value if hasattr(role, "value") else str(role)

@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    try:
        user, access_token, refresh_token = AuthService.login(db, request)
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user={
                "id": str(user.id),
                "email": user.email,
                "phone": user.phone,
                "role": _role_value(user.role),
                "is_active": user.is_active,
                "created_at": user.created_at
            }
        )
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/register", status_code=201, response_model=TokenResponse)
async def register(request: RegisterRequest, db: Session = Depends(get_db)):
    try:
        user, access_token, refresh_token = AuthService.register(db, request)
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user={
                "id": str(user.id),
                "email": user.email,
                "phone": user.phone,
                "role": _role_value(user.role),
                "is_active": user.is_active,
                "created_at": user.created_at
            }
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Register error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(request: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """
    Demande de réinitialisation de mot de passe.
    Génère un token et l'envoie par email (à implémenter).
    """
    try:
        reset_token = AuthService.request_password_reset(db, request.email)
        
        if reset_token:
            # TODO: Envoyer le token par email
            # Pour le moment, on le log (à retirer en production)
            logger.info(f"Reset token for {request.email}: {reset_token}")
            
            # En développement, on peut retourner le token dans la réponse
            # En production, il faut l'envoyer par email uniquement
            return MessageResponse(
                message=f"Si un compte existe avec cet email, un lien de réinitialisation a été envoyé. Token (dev only): {reset_token}"
            )
        else:
            # Pour des raisons de sécurité, on retourne le même message
            # même si l'email n'existe pas
            return MessageResponse(
                message="Si un compte existe avec cet email, un lien de réinitialisation a été envoyé."
            )
    except Exception as e:
        logger.error(f"Forgot password error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    """
    Réinitialise le mot de passe avec le token fourni.
    """
    try:
        AuthService.reset_password(db, request.token, request.new_password)
        return MessageResponse(
            message="Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter."
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Reset password error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")
