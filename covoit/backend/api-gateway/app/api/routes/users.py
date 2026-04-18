from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Response
from app.core.config import settings
import httpx
from typing import Optional

router = APIRouter()

@router.get("/profile/{user_id}")
async def get_profile(user_id: str):
    """Forward profile request to User Service"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}",
            timeout=10.0
        )
    
    if response.status_code != 200:
        raise HTTPException(status_code=404, detail="User not found")
    
    return response.json()

@router.patch("/profile/{user_id}")
async def update_profile(user_id: str, data: dict):
    """Forward profile update to User Service"""
    async with httpx.AsyncClient() as client:
        response = await client.patch(
            f"{settings.USER_SERVICE_URL}/users/{user_id}",
            json=data,
            timeout=10.0
        )
    
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Update failed")
    
    return response.json()

@router.get("/profile/{user_id}/driver")
async def get_driver_profile(user_id: str):
    """Forward driver profile request to User Service"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/driver",
            timeout=10.0
        )

    if response.status_code != 200:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    return response.json()


# ── Vehicle routes ───────────────────────────────────────────────────────────

@router.get("/profile/{user_id}/vehicles")
async def list_vehicles(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles",
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Failed to fetch vehicles")
    return response.json()


@router.post("/profile/{user_id}/vehicles")
async def create_vehicle(user_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles",
            json=data,
            timeout=10.0
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail="Failed to create vehicle")
    return response.json()


@router.get("/profile/{user_id}/vehicles/{vehicle_id}")
async def get_vehicle(user_id: str, vehicle_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles/{vehicle_id}",
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return response.json()


@router.patch("/profile/{user_id}/vehicles/{vehicle_id}")
async def update_vehicle(user_id: str, vehicle_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.patch(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles/{vehicle_id}",
            json=data,
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Update failed")
    return response.json()


@router.delete("/profile/{user_id}/vehicles/{vehicle_id}")
async def delete_vehicle(user_id: str, vehicle_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.delete(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles/{vehicle_id}",
            timeout=10.0
        )
    if response.status_code not in (200, 204):
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return {"status": "deleted"}


@router.post("/profile/{user_id}/vehicles/{vehicle_id}/photos")
async def upload_vehicle_photo(user_id: str, vehicle_id: str, position: int = 0, file: UploadFile = File(...)):
    contents = await file.read()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles/{vehicle_id}/photos",
            params={"position": position},
            files={"file": (file.filename, contents, file.content_type)},
            timeout=30.0
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail="Upload failed")
    return response.json()


@router.delete("/profile/{user_id}/vehicles/{vehicle_id}/photos/{photo_id}")
async def delete_vehicle_photo(user_id: str, vehicle_id: str, photo_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.delete(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/vehicles/{vehicle_id}/photos/{photo_id}",
            timeout=10.0
        )
    if response.status_code not in (200, 204):
        raise HTTPException(status_code=404, detail="Photo not found")
    return {"status": "deleted"}


@router.get("/uploads/vehicles/{filename}")
async def serve_vehicle_photo(filename: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/uploads/vehicles/{filename}",
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=404, detail="Photo not found")
    return Response(
        content=response.content,
        media_type=response.headers.get("content-type", "image/jpeg"),
    )


# ── Contact d'urgence ────────────────────────────────────────────────────────

@router.get("/profile/{user_id}/emergency-contact")
async def get_emergency_contact(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/emergency-contact",
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Failed to fetch emergency contact")
    return response.json()


@router.put("/profile/{user_id}/emergency-contact")
async def set_emergency_contact(user_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/emergency-contact",
            json=data,
            timeout=10.0
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Failed to set emergency contact")
    return response.json()


# ── KYC — Vérification d'identité ────────────────────────────────────────────

@router.get("/profile/{user_id}/kyc")
async def get_kyc_status(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/kyc",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Failed to fetch KYC status")
    return response.json()


@router.post("/profile/{user_id}/kyc/verify")
async def verify_identity(
    user_id: str,
    cni_photo: UploadFile = File(...),
    selfie: UploadFile = File(...),
):
    cni_bytes = await cni_photo.read()
    selfie_bytes = await selfie.read()
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.USER_SERVICE_URL}/users/{user_id}/kyc/verify",
            files={
                "cni_photo": (cni_photo.filename, cni_bytes, cni_photo.content_type),
                "selfie": (selfie.filename, selfie_bytes, selfie.content_type),
            },
            timeout=60.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
