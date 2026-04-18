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
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json() if response.text else "Login failed",
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
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json() if response.text else "Registration failed",
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
