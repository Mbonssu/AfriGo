from fastapi import APIRouter, HTTPException, Query
from app.core.config import settings
import httpx
from typing import Optional

router = APIRouter()


@router.get("/posts")
async def get_posts(category: Optional[str] = None, limit: int = Query(default=50, le=100)):
    params = {"limit": limit}
    if category:
        params["category"] = category
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.FORUM_SERVICE_URL}/forum/posts",
            params=params,
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/posts")
async def create_post(data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.FORUM_SERVICE_URL}/forum/posts",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.get("/posts/{post_id}")
async def get_post(post_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.FORUM_SERVICE_URL}/forum/posts/{post_id}",
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/posts/{post_id}/comments")
async def add_comment(post_id: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.FORUM_SERVICE_URL}/forum/posts/{post_id}/comments",
            json=data,
            timeout=10.0,
        )
    if response.status_code not in (200, 201):
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.post("/posts/{post_id}/like")
async def toggle_like(post_id: str, user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.FORUM_SERVICE_URL}/forum/posts/{post_id}/like",
            params={"user_id": user_id},
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.delete(
            f"{settings.FORUM_SERVICE_URL}/forum/posts/{post_id}",
            params={"user_id": user_id},
            timeout=10.0,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()
