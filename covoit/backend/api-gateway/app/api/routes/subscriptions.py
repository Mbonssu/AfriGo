from fastapi import APIRouter, HTTPException
from app.core.config import settings
import httpx

router = APIRouter()


@router.get("/plans")
async def get_plans():
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.SUBSCRIPTION_SERVICE_URL}/subscriptions/plans",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/subscribe")
async def subscribe(data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.SUBSCRIPTION_SERVICE_URL}/subscriptions/subscribe",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/user/{user_id}")
async def get_user_subscription(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.SUBSCRIPTION_SERVICE_URL}/subscriptions/user/{user_id}",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/user/{user_id}/history")
async def get_subscription_history(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.SUBSCRIPTION_SERVICE_URL}/subscriptions/user/{user_id}/history",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/user/{user_id}/cancel")
async def cancel_subscription(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.SUBSCRIPTION_SERVICE_URL}/subscriptions/user/{user_id}/cancel",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
