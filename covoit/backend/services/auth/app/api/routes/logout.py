# Import de FastAPI pour créer les endpoints
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from datetime import datetime
from jose import jwt, JWTError

# Import des dépendances
from app.core.config import settings

# Import du service de blacklist
from app.services.token_blacklist import TokenBlacklistService

# Créer un routeur pour les routes de déconnexion
router = APIRouter()

# Schéma de sécurité HTTP Bearer
security = HTTPBearer()

# ============================================================================
# ENDPOINT : LOGOUT (DÉCONNEXION)
# ============================================================================

@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Déconnecter un utilisateur",
    responses={
        200: {"description": "Déconnexion réussie"},
        401: {"description": "Token invalide ou absent"},
        500: {"description": "Erreur serveur"},
    }
)
def logout(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """
    Endpoint pour déconnecter un utilisateur.
    
    Flux:
    1. Extraire le token JWT du header Authorization
    2. Valider que le token est valide
    3. Ajouter le token à la blacklist Redis
    4. Retourner un message de succès
    5. À la prochaine requête, le token sera refusé
    
    Paramètres:
        credentials: Token JWT du header "Authorization: Bearer ..."
    
    Retour:
        dict: Message de confirmation de déconnexion
    
    Exemple de requête:
    POST /api/auth/logout
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    
    Réponse (200):
    {
        "message": "Déconnexion réussie",
        "timestamp": "2024-01-15T10:30:00"
    }
    
    Erreurs possibles:
    401: Token expiré ou invalide
    500: Erreur Redis
    """
    
    try:
        # Récupérer le token depuis le header
        token = credentials.credentials
        
        # Valider et décoder le token JWT
        try:
            # Décoder le token avec la clé secrète
            payload = jwt.decode(
                # Token JWT
                token,
                # Clé secrète
                settings.SECRET_KEY,
                # Algorithme utilisé
                algorithms=[settings.ALGORITHM]
            )
            
            # Extraire le user_id du payload
            user_id = payload.get("sub")
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token invalide: user_id manquant"
                )
        
        except JWTError as e:
            # Le token est invalide, expiré ou corrompu
            if "expired" in str(e).lower():
                detail = "Token expiré"
            else:
                detail = "Token invalide"
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=detail
            )
        
        # Extraire l'expiration du token
        # Si le token expire dans 15 minutes, on le garde en blacklist 15 minutes
        exp = payload.get("exp")
        if not exp:
            expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        else:
            # exp est un timestamp Unix, calculer le temps restant
            now = datetime.utcnow().timestamp()
            expire_minutes = max(int((exp - now) / 60), 1)  # Au minimum 1 minute
        
        # Ajouter le token à la blacklist Redis
        blacklist_success = TokenBlacklistService.add_token_to_blacklist(
            token=token,
            expires_in=expire_minutes * 60  # Convertir en secondes
        )
        
        if not blacklist_success:
            # Si Redis échoue, on refuse la déconnexion par sécurité
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erreur lors de la déconnexion (service cache indisponible)"
            )
        
        # Retourner un succès
        return {
            "message": "Déconnexion réussie",
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat(),
            "details": "Votre token a été invalidé et ne pourra plus être utilisé"
        }
    
    except HTTPException:
        # Relancer les HTTPExceptions
        raise
    
    except Exception as e:
        # Gérer les erreurs inattendues
        print(f"[ERROR] Erreur lors du logout: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur serveur lors de la déconnexion"
        )

# ============================================================================
# ENDPOINT : VÉRIFIER LE STATUT DE LA BLACKLIST (Admin)
# ============================================================================

@router.get(
    "/blacklist/stats",
    status_code=status.HTTP_200_OK,
    summary="Statistiques de la blacklist (Admin)",
    tags=["Admin"]
)
def get_blacklist_stats():
    """
    Endpoint pour récupérer les statistiques de la blacklist.
    Utile pour le monitoring et le débogage.
    
    Retour:
        dict: Statistiques sur la blacklist
    
    Exemple de requête:
    GET /api/auth/blacklist/stats
    
    Réponse (200):
    {
        "blacklisted_tokens": 42,
        "redis_memory": "2.5M",
        "status": "healthy"
    }
    """
    
    return TokenBlacklistService.get_blacklist_stats()
