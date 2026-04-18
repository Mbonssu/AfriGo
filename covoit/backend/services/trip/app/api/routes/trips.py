# Import du routeur FastAPI pour définir les endpoints
from fastapi import APIRouter, Depends, HTTPException, status

# Import de la session de base de données
from sqlalchemy.orm import Session

# Import des DTOs Pydantic
from app.schemas.trip import (
    TripCreate, TripUpdate, TripResponse, TripSearchRequest, 
    TripSearchResponse, ErrorResponse
)

# Import du service métier
from app.services.trip_service import TripService

# Import de la dépendance session
from app.db.session import get_db

# Import logging
import logging

# Import UUID pour les identifiants
from uuid import UUID

# Créer le routeur FastAPI pour les routes relatives aux trajets
router = APIRouter(
    # Préfixe URL: toutes les routes commencent par /trips
    prefix="/trips",
    # Tag pour la documentation Swagger
    tags=["Trips"]
)

# Créer un logger pour tracer les requêtes
logger = logging.getLogger(__name__)


# =====================================================
# ENDPOINTS DE CRÉATION (POST)
# =====================================================

@router.post(
    # Route: POST /trips
    "/",
    # Réponse réussie: code HTTP 201 (Created)
    status_code=status.HTTP_201_CREATED,
    # Type de réponse attendu
    response_model=TripResponse,
    # Description pour la doc Swagger
    summary="Créer un nouveau trajet",
    description="Créer un nouveau trajet avec tous les détails (ville, heure, places, prix, etc)"
)
async def create_trip(
    trip_data: TripCreate,
    db: Session = Depends(get_db)
):
    """
    Crée et publie un nouveau trajet.
    
    **Paramètres requis (dans le body JSON):**
    - departure_city: Ville de départ (ex: "Douala")
    - arrival_city: Ville d'arrivée (ex: "Yaoundé")
    - departure_time: Date/heure de départ (ISO 8601, ex: "2026-04-05T14:30:00")
    - total_seats: Nombre de places (2-8)
    - price_per_seat: Prix en FCFA par place
    - vehicle_model: Modèle du véhicule (ex: "Toyota Fortuner 2020")
    - vehicle_plate: Plaque d'immatriculation (ex: "CC1234")
    - is_prime: (optionnel) Statut Prime du chauffeur
    - waypoints: (optionnel) Étapes intermédiaires
    - comfort_options: (optionnel) Options de confort (ac, smoking, music, luggage, wifi, water)
    
    **Réponse réussie (201):**
    Retourne le trajet créé avec tous ses détails (incluant l'ID généré)
    
    **Erreurs possibles:**
    - 400 Bad Request: Données invalides
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la création
        logger.info(f"Requête POST /trips reçue du chauffeur {trip_data.driver_id}")
        
        # Convertir le driver_id string en UUID
        driver_uuid = UUID(trip_data.driver_id)
        
        # Appeler le service pour créer le trajet
        trip = TripService.create_trip(
            db=db,
            driver_id=driver_uuid,
            trip_data=trip_data
        )
        
        # Logging du succès
        logger.info(f"Trajet créé avec succès: {trip.id}")
        
        # FastAPI retourne automatiquement la réponse en JSON avec code 201
        return trip
    
    except ValueError as e:
        # Erreur métier (données invalides)
        logger.error(f"Erreur métier: {str(e)}")
        # Retourner une erreur HTTP 400
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        # Retourner une erreur HTTP 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la création du trajet"
        )


# =====================================================
# ENDPOINTS DE RECHERCHE (GET /search)
# =====================================================

@router.get(
    # Route: GET /trips/search?from_city=Douala&to_city=Yaoundé&...
    "/search",
    # Type de réponse
    response_model=TripSearchResponse,
    # Code réussi
    status_code=status.HTTP_200_OK,
    # Description
    summary="Rechercher des trajets",
    description="Recherche les trajets selon des critères (ville, date, places, prix, etc)"
)
async def search_trips(
    # Query parameters (dans l'URL après ?)
    # Example: GET /trips/search?from_city=Douala&to_city=Yaoundé&departure_date=2026-04-05&passenger_count=2
    search_request: TripSearchRequest = Depends(),
    # Session de base de données
    db: Session = Depends(get_db)
):
    """
    Recherche les trajets selon des critères spécifiques.
    
    **Paramètres de recherche (dans l'URL):**
    - from_city: Ville de départ (obligatoire)
    - to_city: Ville d'arrivée (obligatoire)
    - departure_date: (optionnel) Date cherchée (format YYYY-MM-DD)
    - passenger_count: (optionnel) Nombre de places (défaut: 1)
    - sort_by: (optionnel) Trier par 'departure_time' ou 'price' (défaut: departure_time)
    
    **Exemple de requête:**
    ```
    GET /trips/search?from_city=Douala&to_city=Yaoundé&departure_date=2026-04-05&passenger_count=2
    ```
    
    **Réponse réussie (200):**
    Retourne une liste de trajets matchant les critères avec filtres appliqués.
    
    **Erreurs possibles:**
    - 400 Bad Request: Paramètres invalides
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la recherche
        logger.info(f"Recherche trajets: {search_request.from_city} → {search_request.to_city}")
        
        # Appeler le service de recherche
        results = TripService.search_trips(db=db, search_request=search_request)
        
        # Logging du nombre de résultats
        logger.info(f"Recherche trouvée {results.total_results} trajets")
        
        # Retourner les résultats
        return results
    
    except ValueError as e:
        # Erreur de validation des paramètres
        logger.error(f"Paramètre invalide: {str(e)}")
        # Retourner une erreur HTTP 400
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        # Retourner une erreur HTTP 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la recherche des trajets"
        )


# =====================================================
# ENDPOINT : ROUTES POPULAIRES (avant /{trip_id} !)
# =====================================================

@router.get(
    "/popular",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les routes les plus populaires",
)
async def get_popular_routes(limit: int = 6, db: Session = Depends(get_db)):
    """Agrège les combinaisons départ→arrivée les plus fréquentes."""
    try:
        from app.models.trip import Trip as TripModel
        from sqlalchemy import func as sa_func

        results = (
            db.query(
                TripModel.departure_city,
                TripModel.arrival_city,
                sa_func.count(TripModel.id).label("trip_count"),
                sa_func.round(sa_func.avg(TripModel.price_per_seat)).label("avg_price"),
            )
            .filter(TripModel.status.in_(["active", "completed", "ongoing"]))
            .group_by(TripModel.departure_city, TripModel.arrival_city)
            .order_by(sa_func.count(TripModel.id).desc())
            .limit(limit)
            .all()
        )

        return {
            "data": [
                {
                    "from": r.departure_city,
                    "to": r.arrival_city,
                    "trip_count": r.trip_count,
                    "avg_price": int(r.avg_price) if r.avg_price else 0,
                }
                for r in results
            ]
        }
    except Exception as e:
        logger.error(f"Erreur popular routes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des routes populaires",
        )


# =====================================================
# ENDPOINTS DE LECTURE (GET)
# =====================================================

@router.get(
    # Route: GET /trips/{trip_id}
    "/{trip_id}",
    # Type de réponse
    response_model=TripResponse,
    # Code réussi: 200 OK (défaut)
    status_code=status.HTTP_200_OK,
    # Description
    summary="Récupérer les détails d'un trajet",
    description="Récupère le détail complet d'un trajet (ville, heure, places, chauffeur, options, etc)"
)
async def get_trip(
    # trip_id vient du chemin (path parameter)
    # Exemple: GET /trips/123e4567-e89b-12d3-a456-426614174000
    # FastAPI le convertit automatiquement en UUID
    trip_id: UUID,
    # Session de base de données injectée
    db: Session = Depends(get_db)
):
    """
    Récupère les détails complets d'un trajet spécifique.
    
    **Paramètre dans l'URL:**
    - trip_id: UUID du trajet (format UUID v4)
    
    **Réponse réussie (200):**
    Retourne le trajet avec tous les détails (waypoints, options, etc)
    
    **Erreurs possibles:**
    - 404 Not Found: Trajet inexistant
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la requête
        logger.info(f"Requête GET /trips/{trip_id}")
        
        # Appeler le service pour récupérer le trajet
        trip = TripService.get_trip_by_id(db=db, trip_id=trip_id)
        
        # Logging du succès
        logger.info(f"Trajet récupéré: {trip_id}")
        
        # Retourner le trajet
        return trip
    
    except ValueError as e:
        # Trajet non trouvé (ValueError levée par le service)
        logger.warning(f"Trajet non trouvé: {trip_id}")
        # Retourner une erreur HTTP 404
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        # Retourner une erreur HTTP 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération du trajet"
        )


# =====================================================
# ENDPOINTS DE MODIFICATION (PATCH/PUT)
# =====================================================

@router.patch(
    # Route: PATCH /trips/{trip_id}
    "/{trip_id}",
    # Type de réponse
    response_model=TripResponse,
    # Code réussi
    status_code=status.HTTP_200_OK,
    # Description
    summary="Modifier un trajet",
    description="Modifie les détails d'un trajet existant (prix, statut, etc). Tous les champs sont optionnels."
)
async def update_trip(
    # trip_id vient du chemin
    trip_id: UUID,
    # Les données à modifier viennent du corps
    # PATCH = mise à jour partielle (champs optionnels)
    trip_data: TripUpdate,
    # Session de base de données
    db: Session = Depends(get_db)
):
    """
    Modifie les détails d'un trajet existant.
    
    **Paramètre dans l'URL:**
    - trip_id: UUID du trajet à modifier
    
    **Paramètres optionnels (dans le body JSON):**
    - departure_city: Nouvelle ville de départ
    - arrival_city: Nouvelle ville d'arrivée
    - departure_time: Nouvelle date/heure
    - price_per_seat: Nouveau prix par place
    - vehicle_model: Nouveau modèle de véhicule
    - status: Nouveau statut (active, ongoing, completed, cancelled)
    
    **Réponse réussie (200):**
    Retourne le trajet modifié.
    
    **Erreurs possibles:**
    - 404 Not Found: Trajet inexistant
    - 400 Bad Request: Données invalides
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la modification
        logger.info(f"Requête PATCH /trips/{trip_id}")
        
        # Appeler le service pour modifier le trajet
        trip = TripService.update_trip(db=db, trip_id=trip_id, trip_data=trip_data)
        
        # Logging du succès
        logger.info(f"Trajet modifié: {trip_id}")
        
        # Retourner le trajet modifié
        return trip
    
    except ValueError as e:
        # Erreur métier (trajet inexistant ou données invalides)
        logger.error(f"Erreur métier: {str(e)}")
        # Retourner une erreur HTTP 404 ou 400 selon le contexte
        if "non trouvé" in str(e):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e)
            )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        # Retourner une erreur HTTP 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la modification du trajet"
        )


# =====================================================
# ENDPOINTS DE SUPPRESSION (DELETE)
# =====================================================

@router.delete(
    # Route: DELETE /trips/{trip_id}
    "/{trip_id}",
    # Code réussi: 204 No Content (suppression réussie, pas de corps)
    status_code=status.HTTP_204_NO_CONTENT,
    # Description
    summary="Supprimer/annuler un trajet",
    description="Annule un trajet existant (soft delete - marque comme CANCELLED)"
)
async def delete_trip(
    # trip_id vient du chemin
    trip_id: UUID,
    # Session de base de données
    db: Session = Depends(get_db)
):
    """
    Annule un trajet existant.
    
    **Paramètre dans l'URL:**
    - trip_id: UUID du trajet à annuler
    
    **Réponse réussie (204):**
    Pas de corps - trajet annulé avec succès.
    
    **Erreurs possibles:**
    - 404 Not Found: Trajet inexistant
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la suppression
        logger.info(f"Requête DELETE /trips/{trip_id}")
        
        # Appeler le service pour annuler le trajet
        TripService.delete_trip(db=db, trip_id=trip_id)
        
        # Logging du succès
        logger.info(f"Trajet annulé: {trip_id}")
        
        # Retourner une réponse 204 (pas de corps)
        # FastAPI gère automatiquement la suppression
        return None
    
    except ValueError as e:
        # Trajet non trouvé
        logger.warning(f"Trajet non trouvé: {trip_id}")
        # Retourner une erreur HTTP 404
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        # Retourner une erreur HTTP 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la suppression du trajet"
        )


# =====================================================
# ENDPOINTS UTILITAIRES
# =====================================================

@router.post(
    # Route: POST /trips/{trip_id}/book
    "/{trip_id}/book",
    # Code réussi
    status_code=status.HTTP_200_OK,
    # Description
    summary="Réserver une ou plusieurs places",
    description="Réserve une ou plusieurs places dans un trajet existant"
)
async def book_seat(
    # trip_id vient du chemin
    trip_id: UUID,
    # Nombre de places à réserver (dans le body ou query)
    # Exemple: {"passenger_count": 2}
    passenger_count: int = 1,
    # Session de base de données
    db: Session = Depends(get_db)
):
    """
    Réserve une ou plusieurs places dans un trajet.
    
    **Paramètres:**
    - trip_id: UUID du trajet (dans l'URL)
    - passenger_count: Nombre de places à réserver (query param, défaut: 1)
    
    **Exemple de requête:**
    ```
    POST /trips/123e4567-e89b-12d3-a456-426614174000/book?passenger_count=2
    ```
    
    **Réponse réussie (200):**
    ```json
    {"success": true, "message": "Places réservées avec succès"}
    ```
    
    **Erreurs possibles:**
    - 404 Not Found: Trajet inexistant
    - 400 Bad Request: Pas assez de places disponibles
    - 500 Internal Server Error: Erreur serveur
    """
    
    try:
        # Logging de la réservation
        logger.info(f"Réservation {passenger_count} place(s) trajet {trip_id}")
        
        # Appeler le service pour réserver les places
        success = TripService.book_seat(
            db=db,
            trip_id=trip_id,
            passenger_count=passenger_count
        )
        
        # Vérifier si la réservation a réussi
        if not success:
            # Pas assez de places
            logger.warning(f"Pas assez de places pour trajet {trip_id}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nombre de places insuffisant pour cette réservation"
            )
        
        # Logging du succès
        logger.info(f"Réservation réussie pour trajet {trip_id}")
        
        # Retourner un message de succès
        return {
            "success": True,
            "message": f"{passenger_count} place(s) réservée(s) avec succès",
            "trip_id": str(trip_id)
        }
    
    except ValueError as e:
        # Trajet non trouvé ou erreur métier
        logger.error(f"Erreur métier: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    
    except Exception as e:
        # Erreur inattendue
        logger.error(f"Erreur serveur: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la réservation"
        )


# Note pour les développeurs:
# Ce routeur est enregistré dans main.py avec: app.include_router(router)
# Les routes complètes deviennent: /trips/, /trips/{trip_id}, /trips/search, etc.


@router.get(
    "/driver/{driver_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les trajets d'un chauffeur",
)
async def get_driver_trips(driver_id: str, db: Session = Depends(get_db)):
    """Retourne tous les trajets publiés par un chauffeur donné."""
    try:
        from uuid import UUID as _UUID
        driver_uuid = _UUID(driver_id)
        trips = TripService.get_trips_by_driver(db=db, driver_id=driver_uuid)
        return {"data": [t.model_dump(mode="json") for t in trips]}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        logger.error(f"Erreur serveur: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Erreur serveur")
