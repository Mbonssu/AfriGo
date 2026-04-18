from fastapi import APIRouter, HTTPException
from app.core.config import settings
import httpx

router = APIRouter()


@router.post("/start")
async def start_tracking(data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.TRACKING_SERVICE_URL}/tracking/start",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/trip/{trip_id}")
async def get_tracking(trip_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.TRACKING_SERVICE_URL}/tracking/trip/{trip_id}",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/trip/{trip_id}/position")
async def update_position(trip_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.TRACKING_SERVICE_URL}/tracking/trip/{trip_id}/position",
            json=data,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/trip/{trip_id}/step/{step_id}")
async def update_step(trip_id: str, step_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.TRACKING_SERVICE_URL}/tracking/trip/{trip_id}/step/{step_id}",
            json=data,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/trip/{trip_id}/complete")
async def complete_tracking(trip_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.TRACKING_SERVICE_URL}/tracking/trip/{trip_id}/complete",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/trip/{trip_id}/safety-location")
async def send_safety_location(trip_id: str, data: dict):
    """Transfère la position de sécurité au tracking service."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.TRACKING_SERVICE_URL}/tracking/trip/{trip_id}/safety-location",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
