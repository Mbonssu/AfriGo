"""Authentification WebSocket par query param ?token=xxx"""
import jwt
import logging
from fastapi import WebSocket, status
from app.core.config import settings
from app.middleware.token_blacklist import redis_client as blacklist_redis

logger = logging.getLogger(__name__)


async def authenticate_ws(websocket: WebSocket) -> str | None:
    """
    Authentifie une connexion WebSocket via le query param 'token'.
    Retourne le user_id si valide, None sinon (et ferme la connexion).
    """
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token manquant")
        return None

    # Vérifier la blacklist Redis
    if blacklist_redis:
        try:
            if blacklist_redis.get(f"token_blacklist:{token}"):
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token révoqué")
                return None
        except Exception:
            pass

    # Décoder le JWT
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token invalide")
            return None
        return user_id
    except jwt.ExpiredSignatureError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token expiré")
        return None
    except jwt.InvalidTokenError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Token invalide")
        return None
