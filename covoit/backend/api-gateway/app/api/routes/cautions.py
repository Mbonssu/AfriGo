from fastapi import APIRouter, HTTPException, Query
from app.core.config import settings
import httpx
from typing import Optional

router = APIRouter()


@router.get("/user/{user_id}")
async def get_user_cautions(user_id: str, status: Optional[str] = None):
    params = {}
    if status:
        params["status"] = status
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.CAUTION_SERVICE_URL}/cautions/user/{user_id}",
            params=params,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/user/{user_id}/summary")
async def get_caution_summary(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.CAUTION_SERVICE_URL}/cautions/user/{user_id}/summary",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("")
async def create_caution(data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.CAUTION_SERVICE_URL}/cautions",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/{caution_id}/refund")
async def refund_caution(caution_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.CAUTION_SERVICE_URL}/cautions/{caution_id}/refund",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.put("/{caution_id}/retain")
async def retain_caution(caution_id: str, reason: Optional[str] = None):
    params = {}
    if reason:
        params["reason"] = reason
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.CAUTION_SERVICE_URL}/cautions/{caution_id}/retain",
            params=params,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
