"""WebSocket temps réel pour les notifications — /ws/notifications?token=xxx"""
import asyncio
import json
import logging
import redis.asyncio as aioredis
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.config import settings
from app.api.websockets import authenticate_ws

logger = logging.getLogger(__name__)
router = APIRouter()

# Connexions actives par user : {user_id: websocket}
_connections: dict[str, WebSocket] = {}


@router.websocket("/ws/notifications")
async def notifications_ws(websocket: WebSocket):
    """
    WebSocket notifications : écoute les nouvelles notifications sur Redis
    'notifications:{user_id}' et les pousse en temps réel au client.
    Reste ouvert en permanence tant que l'app est au premier plan.
    """
    await websocket.accept()
    user_id = await authenticate_ws(websocket)
    if not user_id:
        return

    # Enregistrer la connexion (1 seule par user)
    _connections[user_id] = websocket
    logger.info(f"[WS-NOTIF] {user_id} connecté aux notifications")

    # Souscrire au canal Redis de cet utilisateur
    r = aioredis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, db=1, decode_responses=True)
    pubsub = r.pubsub()
    await pubsub.subscribe(f"notifications:{user_id}")

    async def listen_redis():
        """Écoute Redis et pousse les notifications au client WS."""
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = message["data"]
                    ws = _connections.get(user_id)
                    if ws:
                        try:
                            await ws.send_text(data)
                        except Exception:
                            _connections.pop(user_id, None)
        except asyncio.CancelledError:
            pass

    redis_task = asyncio.create_task(listen_redis())

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        logger.info(f"[WS-NOTIF] {user_id} déconnecté des notifications")
    finally:
        redis_task.cancel()
        _connections.pop(user_id, None)
        await pubsub.unsubscribe(f"notifications:{user_id}")
        await pubsub.aclose()
        await r.aclose()
