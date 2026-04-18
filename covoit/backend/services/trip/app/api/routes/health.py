# Import du routeur FastAPI pour définir les endpoints
from fastapi import APIRouter, status

# Créer un routeur FastAPI pour les routes de santé
router = APIRouter(
    # Tags pour la doc Swagger
    tags=["Health"]
)


# =====================================================
# ENDPOINT DE SANTÉ DU SERVICE
# =====================================================

@router.get(
    # Route: GET /health
    "/health",
    # Code réussi: 200 OK
    status_code=status.HTTP_200_OK,
    # Description
    summary="Vérifier l'état du service",
    description="Endpoint pour vérifier que le Trip Service est opérationnel"
)
async def health_check():
    """
    Endpoint de health check pour vérifier que le service répond.
    
    Utilisé par:
    - Docker: healthcheck dans le Dockerfile
    - Kubernetes: liveness probe et readiness probe
    - API Gateway: vérification de disponibilité
    - Monitoring: surveillance de l'état du service
    
    **Réponse réussie (200):**
    ```json
    {
        "status": "healthy",
        "service": "Trip Service",
        "version": "1.0.0"
    }
    ```
    """
    
    # Retourner un objet JSON indiquant que le service est en bonne santé
    return {
        # Status: "healthy" = service prêt
        "status": "healthy",
        # Nom du service
        "service": "Trip Service",
        # Version du service
        "version": "1.0.0"
    }
