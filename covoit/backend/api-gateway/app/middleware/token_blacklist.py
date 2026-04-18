# Import de FastAPI pour les middlewares
from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
import redis

# Import de la configuration
from app.core.config import settings

# ============================================================================
# CONNEXION À REDIS
# ============================================================================

# Créer une connexion Redis pour vérifier la blacklist
try:
    redis_client = redis.Redis(
        # Hôte du serveur Redis (même hôte pour tous les services)
        host=settings.REDIS_HOST,
        # Port du serveur Redis
        port=settings.REDIS_PORT,
        # Numéro de la base de données
        db=0,
        # Décoder les réponses en UTF-8
        decode_responses=True,
    )
    # Tester la connexion
    redis_client.ping()
    print("[MIDDLEWARE] Connexion Redis établie pour la vérification de blacklist")
except Exception as e:
    print(f"[WARNING] Impossible de se connecter à Redis: {str(e)}")
    redis_client = None

# ============================================================================
# MIDDLEWARE DE VÉRIFICATION DE BLACKLIST
# ============================================================================

class TokenBlacklistMiddleware(BaseHTTPMiddleware):
    """
    Middleware FastAPI pour vérifier que les tokens JWT ne sont pas blacklistés.
    
    Fonctionnement:
    1. Intercepter chaque requête
    2. Extraire le token JWT du header Authorization
    3. Vérifier qu'il n'est pas dans la blacklist Redis
    4. Refuser la requête si le token est blacklisté
    
    Cela empêche l'utilisation de tokens après logout.
    """
    
    # Préfixe des clés Redis
    BLACKLIST_PREFIX = "token_blacklist:"
    
    # Routes qui ne nécessitent pas de vérification
    EXEMPT_ROUTES = [
        "/health",
        "/api/auth/login",
        "/api/auth/register",
        "/ws/",
        "/docs",
        "/redoc",
        "/openapi.json",
    ]
    
    def __init__(self, app):
        """
        Initialiser le middleware.
        
        Paramètres:
            app: L'application FastAPI
        """
        super().__init__(app)
        self.app = app
    
    async def dispatch(self, request: Request, call_next):
        """
        Intercepter la requête et vérifier la blacklist.
        
        Paramètres:
            request: La requête HTTP
            call_next: Fonction pour continuer vers le endpoint
        
        Retour:
            Response: La réponse HTTP
        """
        
        # Vérifier si Redis est disponible
        if redis_client is None:
            # Redis indisponible → Laisser passer par précaution
            # (Ne pas bloquer l'API complète si Redis est down)
            print("[WARNING] Redis indisponible, requête autorisée par défaut")
            response = await call_next(request)
            return response
        
        # Vérifier si c'est une route exemptée (pas besoin de vérifier)
        request_path = request.url.path
        if any(request_path.startswith(exempt) for exempt in self.EXEMPT_ROUTES):
            # Route exemptée → laisser passer
            response = await call_next(request)
            return response
        
        # Extraire le token du header Authorization
        auth_header = request.headers.get("authorization")
        
        if not auth_header:
            # Pas de header Authorization → laisser l'endpoint gérer l'erreur
            response = await call_next(request)
            return response
        
        # Le format est "Bearer <token>"
        try:
            parts = auth_header.split()
            if len(parts) != 2 or parts[0].lower() != "bearer":
                # Format invalide → laisser l'endpoint gérer
                response = await call_next(request)
                return response
            
            token = parts[1]
            
            # Vérifier si le token est blacklisté
            is_blacklisted = self._is_token_blacklisted(token)
            
            if is_blacklisted:
                # Token blacklisté → refuser la requête
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "detail": "Token a été invalidé (logout effectué)",
                        "code": "TOKEN_BLACKLISTED"
                    }
                )
            
            # Token valide → laisser passer
            response = await call_next(request)
            return response
        
        except Exception as e:
            # En cas d'erreur → laisser passer par précaution
            print(f"[WARNING] Erreur lors de la vérification blacklist: {str(e)}")
            response = await call_next(request)
            return response
    
    def _is_token_blacklisted(self, token: str) -> bool:
        """
        Vérifier si un token est dans la blacklist Redis.
        
        Paramètres:
            token: Le token JWT à vérifier
        
        Retour:
            bool: True si blacklisté, False sinon
        """
        
        try:
            # Créer la clé Redis
            blacklist_key = f"{self.BLACKLIST_PREFIX}{token}"
            
            # Vérifier si la clé existe
            result = redis_client.exists(blacklist_key)
            
            # result = 0 → n'existe pas (valide)
            # result = 1 → existe (blacklisté)
            return result == 1
        
        except Exception as e:
            # En cas d'erreur Redis → accepter le token pour ne pas bloquer l'API
            print(f"[ERROR] Erreur Redis lors de la vérification: {str(e)}")
            return False
