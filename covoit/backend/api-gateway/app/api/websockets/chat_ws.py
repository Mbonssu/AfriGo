"""WebSocket temps réel pour le chat — /ws/chat/{room_id}?token=xxx"""
import asyncio
import json
import logging
import redis.asyncio as aioredis
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.config import settings
from app.api.websockets import authenticate_ws

logger = logging.getLogger(__name__)
router = APIRouter()

# Connexions actives par room : {room_id: {user_id: websocket}}
_connections: dict[str, dict[str, WebSocket]] = {}


@router.websocket("/ws/chat/{room_id}")
async def chat_ws(websocket: WebSocket, room_id: str):
    """
    WebSocket chat : écoute les messages publiés sur Redis 'chat:{room_id}'
    et les relaye aux participants connectés.
    """
    await websocket.accept()
    user_id = await authenticate_ws(websocket)
    if not user_id:
        return

    # Enregistrer la connexion
    if room_id not in _connections:
        _connections[room_id] = {}
    _connections[room_id][user_id] = websocket
    logger.info(f"[WS-CHAT] {user_id} connecté à room {room_id}")

    # Souscrire au canal Redis
    r = aioredis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, db=1, decode_responses=True)
    pubsub = r.pubsub()
    await pubsub.subscribe(f"chat:{room_id}")

    async def listen_redis():
        """Écoute Redis et relaye aux clients WS de cette room."""
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = message["data"]
                    # Envoyer à tous les participants de la room sauf l'expéditeur
                    parsed = json.loads(data)
                    sender_id = parsed.get("message", {}).get("sender_id")
                    for uid, ws in list(_connections.get(room_id, {}).items()):
                        if uid != sender_id:
                            try:
                                await ws.send_text(data)
                            except Exception:
                                _connections[room_id].pop(uid, None)
        except asyncio.CancelledError:
            pass

    redis_task = asyncio.create_task(listen_redis())

    try:
        while True:
            # On écoute les messages du client (ex: ping/typing indicators)
            text = await websocket.receive_text()
            # Pour l'instant on ignore les messages client — tout passe par HTTP POST
    except WebSocketDisconnect:
        logger.info(f"[WS-CHAT] {user_id} déconnecté de room {room_id}")
    finally:
        redis_task.cancel()
        _connections.get(room_id, {}).pop(user_id, None)
        if room_id in _connections and not _connections[room_id]:
            del _connections[room_id]
        await pubsub.unsubscribe(f"chat:{room_id}")
        await pubsub.aclose()
        await r.aclose()
