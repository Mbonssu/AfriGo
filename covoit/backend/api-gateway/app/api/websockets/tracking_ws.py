"""WebSocket temps réel pour le tracking GPS — /ws/tracking/{trip_id}?token=xxx"""
import asyncio
import json
import logging
import redis.asyncio as aioredis
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.config import settings
from app.api.websockets import authenticate_ws

logger = logging.getLogger(__name__)
router = APIRouter()

# Connexions actives par trip : {trip_id: {user_id: websocket}}
_connections: dict[str, dict[str, WebSocket]] = {}


@router.websocket("/ws/tracking/{trip_id}")
async def tracking_ws(websocket: WebSocket, trip_id: str):
    """
    WebSocket tracking : écoute les mises à jour de position sur Redis 'tracking:{trip_id}'
    et les relaye à tous les passagers/chauffeur connectés.
    """
    await websocket.accept()
    user_id = await authenticate_ws(websocket)
    if not user_id:
        return

    # Enregistrer la connexion
    if trip_id not in _connections:
        _connections[trip_id] = {}
    _connections[trip_id][user_id] = websocket
    logger.info(f"[WS-TRACKING] {user_id} connecté au tracking trip {trip_id}")

    # Souscrire au canal Redis
    r = aioredis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, db=1, decode_responses=True)
    pubsub = r.pubsub()
    await pubsub.subscribe(f"tracking:{trip_id}")

    async def listen_redis():
        """Écoute Redis et broadcast la position à tous les clients WS."""
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = message["data"]
                    for uid, ws in list(_connections.get(trip_id, {}).items()):
                        try:
                            await ws.send_text(data)
                        except Exception:
                            _connections[trip_id].pop(uid, None)
        except asyncio.CancelledError:
            pass

    redis_task = asyncio.create_task(listen_redis())

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        logger.info(f"[WS-TRACKING] {user_id} déconnecté du tracking trip {trip_id}")
    finally:
        redis_task.cancel()
        _connections.get(trip_id, {}).pop(user_id, None)
        if trip_id in _connections and not _connections[trip_id]:
            del _connections[trip_id]
        await pubsub.unsubscribe(f"tracking:{trip_id}")
        await pubsub.aclose()
        await r.aclose()
