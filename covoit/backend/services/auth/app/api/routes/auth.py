from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, AuthResponse
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
