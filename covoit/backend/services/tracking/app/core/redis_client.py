import redis
import json
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

_redis_client = None


def get_redis() -> redis.Redis | None:
    global _redis_client
    if _redis_client is None:
        try:
            _redis_client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                db=1,
                decode_responses=True,
            )
            _redis_client.ping()
            logger.info("[REDIS] Connexion Redis établie (tracking)")
        except Exception as e:
            logger.warning(f"[REDIS] Impossible de se connecter: {e}")
            _redis_client = None
    return _redis_client


def publish_event(channel: str, data: dict):
    """Publie un événement JSON sur un canal Redis."""
    r = get_redis()
    if r:
        try:
            r.publish(channel, json.dumps(data))
        except Exception as e:
            logger.warning(f"[REDIS] Publish échoué sur {channel}: {e}")
