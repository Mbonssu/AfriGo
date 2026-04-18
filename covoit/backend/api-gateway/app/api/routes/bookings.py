# Import de FastAPI pour créer les endpoints
from fastapi import APIRouter, Depends, HTTPException, status
import httpx

# Import de la configuration pour les URLs des services
from app.core.config import settings

# Créer un routeur pour les routes du Booking Service
router = APIRouter(tags=["Bookings"])

# ============================================================================
# ROUTE 1 : CRÉER UNE RÉSERVATION
# ============================================================================

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    summary="Créer une nouvelle réservation",
)
async def create_booking(request: dict):
    """
    Transfère la requête vers le Booking Service (port 8004).
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Erreur du Booking Service")
        )
    
    return response.json()

# ============================================================================
# ROUTE 2 : RÉCUPÉRER UNE RÉSERVATION
# ============================================================================

@router.get(
    "/{booking_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer une réservation par son ID",
)
async def get_booking(booking_id: str):
    """
    Récupère les détails d'une réservation.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}"
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Réservation non trouvée")
        )
    
    return response.json()

# ============================================================================
# ROUTE 3 : RÉCUPÉRER LES RÉSERVATIONS D'UN PASSAGER
# ============================================================================

@router.get(
    "/passenger/{passenger_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les réservations d'un passager",
)
async def get_passenger_bookings(passenger_id: str, limit: int = 20, offset: int = 0):
    """
    Récupère l'historique des réservations d'un passager.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/passenger/{passenger_id}",
            params={"limit": limit, "offset": offset}
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la récupération des réservations"
        )
    
    return response.json()

# ============================================================================
# ROUTE 4 : RÉCUPÉRER LES RÉSERVATIONS D'UN TRAJET
# ============================================================================

@router.get(
    "/trip/{trip_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les réservations d'un trajet",
)
async def get_trip_bookings(trip_id: str, limit: int = 50, offset: int = 0):
    """
    Récupère toutes les réservations pour un trajet donné.
    Utile pour le conducteur pour voir les passagers réservés.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/trip/{trip_id}",
            params={"limit": limit, "offset": offset}
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la récupération des réservations"
        )
    
    return response.json()

# ============================================================================
# ROUTE 5 : RECHERCHER DES RÉSERVATIONS
# ============================================================================

@router.post(
    "/search",
    status_code=status.HTTP_200_OK,
    summary="Rechercher les réservations avec filtres",
)
async def search_bookings(request: dict):
    """
    Recherche les réservations avec filtres.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/search",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la recherche"
        )
    
    return response.json()

# ============================================================================
# ROUTE 6 : METTRE À JOUR UNE RÉSERVATION
# ============================================================================

@router.put(
    "/{booking_id}",
    status_code=status.HTTP_200_OK,
    summary="Mettre à jour une réservation",
)
async def update_booking(booking_id: str, request: dict):
    """
    Met à jour une réservation.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la mise à jour"
        )
    
    return response.json()

# ============================================================================
# ROUTE 7 : CONFIRMER UNE RÉSERVATION
# ============================================================================

@router.post(
    "/{booking_id}/confirm",
    status_code=status.HTTP_200_OK,
    summary="Confirmer une réservation après paiement",
)
async def confirm_booking(booking_id: str, request: dict):
    """
    Confirme une réservation après paiement réussi.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/confirm",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la confirmation"
        )
    
    return response.json()

# ============================================================================
# ROUTE 8 : ANNULER UNE RÉSERVATION
# ============================================================================

@router.post(
    "/{booking_id}/cancel",
    status_code=status.HTTP_200_OK,
    summary="Annuler une réservation",
)
async def cancel_booking(booking_id: str, request: dict):
    """
    Annule une réservation.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/cancel",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de l'annulation"
        )
    
    return response.json()

# ============================================================================
# ROUTE 8b : ACCEPTER UNE RÉSERVATION (CONDUCTEUR)
# ============================================================================

@router.post(
    "/{booking_id}/accept",
    status_code=status.HTTP_200_OK,
    summary="Le conducteur accepte une réservation",
)
async def accept_booking(booking_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/accept"
        )
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Erreur lors de l'acceptation")
        )
    return response.json()

# ============================================================================
# ROUTE 8c : REFUSER UNE RÉSERVATION (CONDUCTEUR)
# ============================================================================

@router.post(
    "/{booking_id}/reject",
    status_code=status.HTTP_200_OK,
    summary="Le conducteur refuse une réservation",
)
async def reject_booking(booking_id: str, request: dict = None):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/reject",
            json=request or {}
        )
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Erreur lors du refus")
        )
    return response.json()

# ============================================================================
# ROUTE 9 : MARQUER COMME COMPLÉTÉ
# ============================================================================

@router.post(
    "/{booking_id}/complete",
    status_code=status.HTTP_200_OK,
    summary="Marquer une réservation comme complétée",
)
async def complete_booking(booking_id: str):
    """
    Marque une réservation comme complétée (trajet terminé).
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/complete"
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la complétion"
        )
    
    return response.json()

# ============================================================================
# ROUTE 10 : MARQUER COMME NO-SHOW
# ============================================================================

@router.post(
    "/{booking_id}/no-show",
    status_code=status.HTTP_200_OK,
    summary="Marquer une réservation comme no-show",
)
async def mark_no_show(booking_id: str):
    """
    Marque une réservation comme no-show (passager absent).
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/no-show"
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors du marquage no-show"
        )
    
    return response.json()

# ============================================================================
# ROUTE 11 : AJOUTER UNE NOTE
# ============================================================================

@router.post(
    "/{booking_id}/notes",
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter une note à une réservation",
)
async def add_booking_note(booking_id: str, request: dict):
    """
    Ajoute une note/commentaire à une réservation.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/notes",
            json=request
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de l'ajout de la note"
        )
    
    return response.json()

# ============================================================================
# ROUTE 12 : RÉCUPÉRER LES NOTES
# ============================================================================

@router.get(
    "/{booking_id}/notes",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les notes d'une réservation",
)
async def get_booking_notes(booking_id: str):
    """
    Récupère toutes les notes d'une réservation.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/notes"
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la récupération des notes"
        )
    
    return response.json()

# ============================================================================
# ROUTE 13 : STATISTIQUES
# ============================================================================

@router.get(
    "/stats/passenger/{passenger_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les statistiques de réservation",
)
async def get_passenger_stats(passenger_id: str):
    """
    Récupère les statistiques de réservation d'un passager.
    """
    
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/stats/passenger/{passenger_id}"
        )
    
    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la récupération des statistiques"
        )
    
    return response.json()


# ============================================================================
# ROUTE 14 : RÉCUPÉRER LE CODE D'EMBARQUEMENT (PASSAGER)
# ============================================================================

@router.get(
    "/{booking_id}/boarding-code",
    status_code=status.HTTP_200_OK,
    summary="Récupérer le code d'embarquement d'une réservation",
)
async def get_boarding_code(booking_id: str):
    """
    Proxy vers booking-service : récupère le code PIN d'embarquement.
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/boarding-code"
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Erreur code embarquement")
        )

    return response.json()


# ============================================================================
# ROUTE 15 : VÉRIFIER L'EMBARQUEMENT (CHAUFFEUR)
# ============================================================================

@router.post(
    "/{booking_id}/verify-boarding",
    status_code=status.HTTP_200_OK,
    summary="Vérifier l'embarquement d'un passager",
)
async def verify_boarding(booking_id: str, request: dict):
    """
    Proxy vers booking-service : le chauffeur vérifie le code du passager.
    """
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.BOOKING_SERVICE_URL}/bookings/{booking_id}/verify-boarding",
            json=request,
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=response.json().get("detail", "Erreur vérification embarquement")
        )

    return response.json()


# ============================================================================
# ROUTE 16 : STATUT EMBARQUEMENT D'UN TRAJET (CHAUFFEUR)
# ============================================================================

@router.get(
    "/trip/{trip_id}/boarding-status",
    status_code=status.HTTP_200_OK,
    summary="Statut embarquement de tous les passagers d'un trajet",
)
async def get_trip_boarding_status(trip_id: str):
    """
    Proxy vers booking-service : statut boarding de tous les passagers du trajet.
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_SERVICE_URL}/bookings/trip/{trip_id}/boarding-status"
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail="Erreur lors de la récupération du statut embarquement"
        )

    return response.json()
