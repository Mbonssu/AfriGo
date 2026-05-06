# Import du routeur FastAPI pour créer les endpoints
from fastapi import APIRouter, HTTPException, status, Query
# Import de httpx pour faire des appels HTTP vers d'autres services
import httpx
# Import de la configuration pour les URLs des services
from app.core.config import settings
# Import logging
import logging

# Créer un logger pour tracer les forwarding
logger = logging.getLogger(__name__)

# Créer un routeur pour les routes des trajets
router = APIRouter()


# =====================================================
# ENDPOINTS DE CRÉATION (POST /trips)
# =====================================================

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_trip(request: dict):
    """
    Crée un nouveau trajet.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête POST /api/trips → Forward vers http://trip-service:8003/trips
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: POST /api/trips → Trip Service")
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête vers le Trip Service
            # request.dict() convertit le modèle Pydantic en dictionnaire JSON
            response = await client.post(
                # URL du Trip Service (depuis la config)
                f"{settings.TRIP_SERVICE_URL}/trips/",
                # Body de la requête (données du trajet)
                json=request,
                # Timeout de 10 secondes pour la réponse
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 201)
        if response.status_code != 201:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur du service
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur lors de la création du trajet"
            )
        
        # Logging du succès
        logger.info(f"Gateway: Trajet créé avec succès")
        
        # Retourner la réponse du Trip Service
        return response.json()
    
    except httpx.RequestError as e:
        # Erreur de connexion vers le Trip Service
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# =====================================================
# ENDPOINTS DE RECHERCHE (GET /search)
# =====================================================

@router.get("/search", status_code=status.HTTP_200_OK)
async def search_trips(
    # Query parameters (optionnels pour permettre de charger tous les trajets)
    from_city: str = Query(None, description="Ville de départ (optionnel)"),
    to_city: str = Query(None, description="Ville d'arrivée (optionnel)"),
    departure_date: str = Query(None, description="Date de départ (YYYY-MM-DD, optionnel)"),
    passenger_count: int = Query(1, description="Nombre de passagers"),
    sort_by: str = Query("departure_time", description="Trier par: departure_time ou price")
):
    """
    Recherche les trajets selon des critères.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête GET /api/trips/search?from_city=X&to_city=Y → Forward vers http://trip-service:8003/trips/search?...
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: GET /api/trips/search - {from_city} → {to_city}")
        
        # Construire les query parameters à forwarder
        # Inclure seulement les paramètres fournis (non None et non vides)
        params = {
            "passenger_count": passenger_count,
            "sort_by": sort_by
        }
        
        # Ajouter from_city si fourni
        if from_city:
            params["from_city"] = from_city
            
        # Ajouter to_city si fourni
        if to_city:
            params["to_city"] = to_city
        
        # Ajouter departure_date si fourni
        if departure_date:
            params["departure_date"] = departure_date
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête vers le Trip Service
            response = await client.get(
                # URL du Trip Service avec /search
                f"{settings.TRIP_SERVICE_URL}/trips/search",
                # Paramètres de requête
                params=params,
                # Timeout
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 200)
        if response.status_code != 200:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur lors de la recherche"
            )
        
        # Logging du succès
        result = response.json()
        logger.info(f"Gateway: {result.get('total_results', 0)} trajets trouvés")
        
        # Retourner la réponse du Trip Service
        return result
    
    except httpx.RequestError as e:
        # Erreur de connexion
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# =====================================================
# ENDPOINT : ROUTES POPULAIRES (avant /{trip_id} !)
# =====================================================

@router.get("/popular", status_code=status.HTTP_200_OK)
async def get_popular_routes(limit: int = 6):
    """Récupère les routes les plus populaires via le Trip Service."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.TRIP_SERVICE_URL}/trips/popular",
                params={"limit": limit},
                timeout=10.0,
            )
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur",
            )
        return response.json()
    except httpx.RequestError as e:
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible",
        )


# =====================================================
# ENDPOINTS DE LECTURE (GET /trips/{trip_id})
# =====================================================

@router.get("/{trip_id}", status_code=status.HTTP_200_OK)
async def get_trip(trip_id: str):
    """
    Récupère les détails d'un trajet spécifique.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête GET /api/trips/{trip_id} → Forward vers http://trip-service:8003/trips/{trip_id}
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: GET /api/trips/{trip_id} → Trip Service")
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête vers le Trip Service
            response = await client.get(
                # URL du Trip Service avec l'ID du trajet
                f"{settings.TRIP_SERVICE_URL}/trips/{trip_id}",
                # Timeout
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 200)
        if response.status_code != 200:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Trajet non trouvé"
            )
        
        # Logging du succès
        logger.info(f"Gateway: Trajet {trip_id} récupéré")
        
        # Retourner la réponse du Trip Service
        return response.json()
    
    except httpx.RequestError as e:
        # Erreur de connexion
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# =====================================================
# ENDPOINTS DE MODIFICATION (PATCH /trips/{trip_id})
# =====================================================

@router.patch("/{trip_id}", status_code=status.HTTP_200_OK)
async def update_trip(trip_id: str, request: dict):
    """
    Modifie un trajet existant.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête PATCH /api/trips/{trip_id} → Forward vers http://trip-service:8003/trips/{trip_id}
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: PATCH /api/trips/{trip_id} → Trip Service")
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête PATCH vers le Trip Service
            response = await client.patch(
                # URL du Trip Service
                f"{settings.TRIP_SERVICE_URL}/trips/{trip_id}",
                # Body de la requête
                json=request,
                # Timeout
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 200)
        if response.status_code != 200:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur lors de la modification"
            )
        
        # Logging du succès
        logger.info(f"Gateway: Trajet {trip_id} modifié")
        
        # Retourner la réponse du Trip Service
        return response.json()
    
    except httpx.RequestError as e:
        # Erreur de connexion
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# =====================================================
# ENDPOINTS DE SUPPRESSION (DELETE /trips/{trip_id})
# =====================================================

@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(trip_id: str):
    """
    Annule un trajet existant.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête DELETE /api/trips/{trip_id} → Forward vers http://trip-service:8003/trips/{trip_id}
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: DELETE /api/trips/{trip_id} → Trip Service")
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête DELETE vers le Trip Service
            response = await client.delete(
                # URL du Trip Service
                f"{settings.TRIP_SERVICE_URL}/trips/{trip_id}",
                # Timeout
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 204)
        if response.status_code != 204:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur lors de l'annulation"
            )
        
        # Logging du succès
        logger.info(f"Gateway: Trajet {trip_id} annulé")
        
        # Retourner une réponse 204 (pas de contenu)
        return None
    
    except httpx.RequestError as e:
        # Erreur de connexion
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# =====================================================
# ENDPOINTS UTILITAIRES
# =====================================================

@router.post("/{trip_id}/book", status_code=status.HTTP_200_OK)
async def book_seat(
    trip_id: str,
    # Nombre de places à réserver
    passenger_count: int = Query(1, description="Nombre de places à réserver")
):
    """
    Réserve une ou plusieurs places dans un trajet.
    
    Cette route FORWARD la requête vers le Trip Service
    Requête POST /api/trips/{trip_id}/book → Forward vers http://trip-service:8003/trips/{trip_id}/book
    """
    
    try:
        # Logging de la requête
        logger.info(f"Gateway: POST /api/trips/{trip_id}/book (passagers={passenger_count})")
        
        # Créer un client HTTP asynchrone
        async with httpx.AsyncClient() as client:
            # Forwarder la requête POST vers le Trip Service
            response = await client.post(
                # URL du Trip Service avec /book
                f"{settings.TRIP_SERVICE_URL}/trips/{trip_id}/book",
                # Query parameter
                params={"passenger_count": passenger_count},
                # Timeout
                timeout=10.0
            )
        
        # Vérifier si la requête a réussi (code 200)
        if response.status_code != 200:
            # Logger l'erreur
            logger.error(f"Trip Service error: {response.status_code}")
            # Retourner l'erreur
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur lors de la réservation"
            )
        
        # Logging du succès
        logger.info(f"Gateway: {passenger_count} place(s) réservée(s) pour trajet {trip_id}")
        
        # Retourner la réponse du Trip Service
        return response.json()
    
    except httpx.RequestError as e:
        # Erreur de connexion
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible"
        )


# Note importante:
# Ce routeur est enregistré dans main.py avec: app.include_router(router, prefix="/api/trips")
# Donc toutes les routes ci-dessus sont préfixées par /api/trips
# Exemples d'URLs complètes:
#   POST /api/trips/ → crée un trajet
#   GET /api/trips/{trip_id} → récupère un trajet
#   GET /api/trips/search?... → recherche des trajets
#   PATCH /api/trips/{trip_id} → modifie un trajet
#   DELETE /api/trips/{trip_id} → annule un trajet
#   POST /api/trips/{trip_id}/book → réserve des places
#   GET /api/trips/driver/{driver_id} → trajets d'un chauffeur
#   GET /api/trips/popular → routes les plus populaires


@router.get("/driver/{driver_id}", status_code=status.HTTP_200_OK)
async def get_driver_trips(driver_id: str):
    """Récupère tous les trajets d'un chauffeur via le Trip Service."""
    try:
        logger.info(f"Gateway: GET /api/trips/driver/{driver_id} → Trip Service")
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.TRIP_SERVICE_URL}/trips/driver/{driver_id}",
                timeout=10.0,
            )
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=response.json() if response.text else "Erreur",
            )
        return response.json()
    except httpx.RequestError as e:
        logger.error(f"Erreur connexion Trip Service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Trip Service indisponible",
        )
