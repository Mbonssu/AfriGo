from fastapi import APIRouter, HTTPException, Query
from app.core.config import settings
import httpx
from typing import Optional

router = APIRouter()


@router.get("/room/trip/{trip_id}/users/{user1_id}/{user2_id}")
async def get_or_create_room(trip_id: str, user1_id: str, user2_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.CHAT_SERVICE_URL}/chat/room/trip/{trip_id}/users/{user1_id}/{user2_id}",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/room/{room_id}/messages")
async def get_messages(room_id: str, limit: int = Query(default=50, le=200), before: Optional[str] = None):
    params = {"limit": limit}
    if before:
        params["before"] = before
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.CHAT_SERVICE_URL}/chat/room/{room_id}/messages",
            params=params,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/room/{room_id}/messages")
async def send_message(room_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.CHAT_SERVICE_URL}/chat/room/{room_id}/messages",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/room/{room_id}/read/{user_id}")
async def mark_messages_read(room_id: str, user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.CHAT_SERVICE_URL}/chat/room/{room_id}/read/{user_id}",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/user/{user_id}/rooms")
async def get_user_rooms(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.CHAT_SERVICE_URL}/chat/user/{user_id}/rooms",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
