from fastapi import APIRouter, HTTPException, Query
from app.core.config import settings
import httpx
from typing import Optional

router = APIRouter()


@router.get("/user/{user_id}")
async def get_user_notifications(user_id: str, limit: int = Query(default=50, le=100)):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.NOTIFICATION_SERVICE_URL}/notifications/user/{user_id}",
            params={"limit": limit},
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("")
async def create_notification(data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.NOTIFICATION_SERVICE_URL}/notifications",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/{notification_id}/read")
async def mark_as_read(notification_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.NOTIFICATION_SERVICE_URL}/notifications/{notification_id}/read",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/user/{user_id}/read-all")
async def mark_all_as_read(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.NOTIFICATION_SERVICE_URL}/notifications/user/{user_id}/read-all",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
