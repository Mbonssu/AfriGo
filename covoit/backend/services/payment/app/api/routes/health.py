# Import de FastAPI pour créer les endpoints
from fastapi import APIRouter, status
from datetime import datetime

# Créer un routeur pour les routes de santé
router = APIRouter(tags=["Health"])

# ============================================================================
# ENDPOINT : VÉRIFIER LA SANTÉ DE L'APPLICATION
# ============================================================================

@router.get(
    "/health",
    status_code=status.HTTP_200_OK,
    summary="Vérifier la santé du service de paiement",
    responses={
        200: {"description": "Service en bonne santé"},
        503: {"description": "Service indisponible"},
    }
)
def health_check() -> dict:
    """
    Endpoint pour vérifier que le service Payment est opérationnel.
    
    Utilisé par:
    - Kubernetes pour les liveness/readiness probes
    - Les gestionnaires de charge pour vérifier la santé du service
    - Les scripts de monitoring et alertes
    
    Retour:
        dict: Dictionnaire avec le statut du service
        {
            "status": "healthy",
            "timestamp": "2024-01-15T10:30:00",
            "service": "payment-service",
            "version": "1.0.0"
        }
    
    Exemple de requête:
    GET /health
    
    Réponse (200):
    {
        "status": "healthy",
        "timestamp": "2024-01-15T10:30:00.123456",
        "service": "payment-service",
        "version": "1.0.0"
    }
    """
    
    # Retourner le statut sain avec timestamp actuel
    return {
        "status": "healthy",                          # Statut du service
        "timestamp": datetime.utcnow().isoformat(),  # Timestamp ISO 8601
        "service": "payment-service",                 # Nom du service
        "version": "1.0.0"                            # Version du service
    }
