from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, EmailStr
from app.core.config import settings
import httpx

router = APIRouter()

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    phone: str
    role: str  # "passenger" or "driver"

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

@router.post("/login")
async def login(request: LoginRequest):
    """Forward login request to Auth Service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.AUTH_SERVICE_URL}/auth/login",
                json=request.dict(),
                timeout=10.0
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth Service indisponible",
        )

    if response.status_code != 200:
        # Extraire le message d'erreur du service d'authentification
        error_detail = "Login failed"
        if response.text:
            try:
                error_data = response.json()
                error_detail = error_data.get("detail", error_detail)
            except:
                pass
        raise HTTPException(
            status_code=response.status_code,
            detail=error_detail,
        )

    return response.json()

@router.post("/register")
async def register(request: RegisterRequest):
    """Forward register request to Auth Service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.AUTH_SERVICE_URL}/auth/register",
                json=request.dict(),
                timeout=10.0
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth Service indisponible",
        )

    if response.status_code != 201:
        # Extraire le message d'erreur du service d'authentification
        error_detail = "Registration failed"
        if response.text:
            try:
                error_data = response.json()
                error_detail = error_data.get("detail", error_detail)
            except:
                pass
        raise HTTPException(
            status_code=response.status_code,
            detail=error_detail,
        )

    return response.json()


@router.post("/logout")
async def logout(request: Request):
    """Forward logout request to Auth Service (blacklist token in Redis)"""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token manquant",
        )

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.AUTH_SERVICE_URL}/auth/logout",
                headers={"Authorization": auth_header},
                timeout=10.0,
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth Service indisponible",
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json() if response.text else "Logout failed",
        )

    return response.json()


@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    """Forward forgot password request to Auth Service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.AUTH_SERVICE_URL}/auth/forgot-password",
                json=request.dict(),
                timeout=10.0
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth Service indisponible",
        )

    if response.status_code >= 400:
        error_detail = "Forgot password failed"
        if response.text:
            try:
                error_data = response.json()
                error_detail = error_data.get("detail", error_detail)
            except:
                pass
        raise HTTPException(
            status_code=response.status_code,
            detail=error_detail,
        )

    return response.json()


@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest):
    """Forward reset password request to Auth Service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.AUTH_SERVICE_URL}/auth/reset-password",
                json=request.dict(),
                timeout=10.0
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth Service indisponible",
        )

    if response.status_code >= 400:
        error_detail = "Reset password failed"
        if response.text:
            try:
                error_data = response.json()
                error_detail = error_data.get("detail", error_detail)
            except:
                pass
        raise HTTPException(
            status_code=response.status_code,
            detail=error_detail,
        )

    return response.json()
