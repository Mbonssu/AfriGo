# Import de FastAPI pour créer les endpoints
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

# Import des dépendances
from app.db.session import get_db

# Import des schémas Pydantic
from app.schemas.booking import (
    BookingCreateRequest,
    BookingResponse,
    BookingUpdateRequest,
    BookingSearchRequest,
    BookingSearchResponse,
    BookingConfirmRequest,
    BookingCancelRequest,
    BookingNoteCreateRequest,
    BookingNoteResponse,
    BoardingVerifyRequest,
    BoardingResponse,
)

# Import du service métier
from app.services.booking_service import BookingService

# Créer un routeur FastAPI pour les endpoints de réservation
router = APIRouter(prefix="/bookings", tags=["Bookings"])

# ============================================================================
# ENDPOINT 1 : CRÉER UNE RÉSERVATION
# ============================================================================

@router.post(
    "",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Créer une nouvelle réservation",
)
def create_booking(
    request: BookingCreateRequest,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour créer une nouvelle réservation de trajet.
    
    Flux:
    1. Valider les données (trajet existe, passager existe, places disponibles)
    2. Créer la réservation en base de données avec statut PENDING
    3. Retourner les données de la réservation créée
    4. Le passager doit ensuite effectuer un paiement
    
    Paramètres:
        request: Objet BookingCreateRequest avec:
        - trip_id: UUID du trajet
        - passenger_id: UUID du passager
        - number_of_seats: Nombre de places (1-6)
        - total_price: Prix total en FCFA
        
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation créée (status=pending)
    
    Exemple de requête:
    POST /api/v1/bookings/
    {
        "trip_id": "550e8400-e29b-41d4-a716-446655440000",
        "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
        "number_of_seats": 2,
        "total_price": 5000.0,
        "pickup_location": "3.848,11.502",
        "dropoff_location": "3.868,11.516"
    }
    
    Réponse (201):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "trip_id": "550e8400-e29b-41d4-a716-446655440000",
        "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
        "number_of_seats": 2,
        "total_price": 5000.0,
        "status": "pending",
        "created_at": "2024-01-15T10:30:00",
        "updated_at": "2024-01-15T10:30:00"
    }
    """
    
    try:
        booking = BookingService.create_booking(db, request)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la création de la réservation"
        )

# ============================================================================
# ENDPOINT 2 : RÉCUPÉRER UNE RÉSERVATION
# ============================================================================

@router.get(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer une réservation par son ID",
)
def get_booking(
    booking_id: UUID,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour récupérer les détails complets d'une réservation.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id})
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: Les détails complets de la réservation
    
    Lève HTTPException(404) si la réservation n'existe pas
    
    Exemple de requête:
    GET /api/v1/bookings/550e8400-e29b-41d4-a716-446655440002
    """
    
    booking = BookingService.get_booking_by_id(db, booking_id)
    
    if booking is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Réservation {booking_id} non trouvée"
        )
    
    return booking

# ============================================================================
# ENDPOINT 3 : RÉCUPÉRER LES RÉSERVATIONS D'UN PASSAGER
# ============================================================================

@router.get(
    "/passenger/{passenger_id}",
    response_model=BookingSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer les réservations d'un passager",
)
def get_passenger_bookings(
    passenger_id: UUID,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db)
) -> BookingSearchResponse:
    """
    Endpoint pour récupérer toutes les réservations d'un passager avec pagination.
    
    Paramètres:
        passenger_id: UUID du passager (dans l'URL : /passenger/{passenger_id})
        limit: Nombre de résultats par page (défaut 20, max 100)
        offset: Position de départ pour la pagination (défaut 0)
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingSearchResponse: Liste paginée des réservations
    
    Exemple de requête:
    GET /api/v1/bookings/passenger/550e8400-e29b-41d4-a716-446655440001?limit=10&offset=0
    """
    
    if limit > 100:
        limit = 100
    if limit < 1:
        limit = 1
    if offset < 0:
        offset = 0
    
    return BookingService.get_passenger_bookings(db, passenger_id, limit, offset)

# ============================================================================
# ENDPOINT 4 : RÉCUPÉRER LES RÉSERVATIONS D'UN TRAJET
# ============================================================================

@router.get(
    "/trip/{trip_id}",
    response_model=BookingSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer les réservations d'un trajet",
)
def get_trip_bookings(
    trip_id: UUID,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
) -> BookingSearchResponse:
    """
    Endpoint pour récupérer toutes les réservations pour un trajet donné.
    Utile pour le conducteur pour voir les passagers qui ont réservé.
    
    Paramètres:
        trip_id: UUID du trajet (dans l'URL : /trip/{trip_id})
        limit: Nombre maximum de résultats
        offset: Décalage pour pagination
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingSearchResponse: Réservations pour ce trajet
    """
    
    if limit > 100:
        limit = 100
    if limit < 1:
        limit = 1
    if offset < 0:
        offset = 0
    
    return BookingService.get_trip_bookings(db, trip_id, limit, offset)

# ============================================================================
# ENDPOINT 5 : RECHERCHER LES RÉSERVATIONS
# ============================================================================

@router.post(
    "/search",
    response_model=BookingSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Rechercher les réservations avec filtres",
)
def search_bookings(
    request: BookingSearchRequest,
    db: Session = Depends(get_db)
) -> BookingSearchResponse:
    """
    Endpoint pour rechercher les réservations avec filtres multiples.
    
    Filtres disponibles:
    - trip_id: UUID du trajet
    - passenger_id: UUID du passager
    - status: "pending", "confirmed", "cancelled", "completed", "no_show"
    - min_price / max_price: Plage de prix
    
    Paramètres:
        request: Objet BookingSearchRequest avec les critères
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingSearchResponse: Résultats filtrés et paginés
    
    Exemple de requête:
    POST /api/v1/bookings/search
    {
        "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
        "status": "confirmed",
        "limit": 20,
        "offset": 0
    }
    """
    
    return BookingService.search_bookings(db, request)

# ============================================================================
# ENDPOINT 6 : METTRE À JOUR UNE RÉSERVATION
# ============================================================================

@router.put(
    "/{booking_id}",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Mettre à jour une réservation",
)
def update_booking(
    booking_id: UUID,
    request: BookingUpdateRequest,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour mettre à jour une réservation.
    Seul le statut et les notes du conducteur peuvent être modifiés.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id})
        request: Objet BookingUpdateRequest avec les mise à jours
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation mise à jour
    
    Lève HTTPException(404) si la réservation n'existe pas
    """
    
    try:
        booking = BookingService.update_booking(db, booking_id, request)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour"
        )

# ============================================================================
# ENDPOINT 7 : CONFIRMER UNE RÉSERVATION
# ============================================================================

@router.post(
    "/{booking_id}/confirm",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirmer une réservation après paiement",
)
def confirm_booking(
    booking_id: UUID,
    request: BookingConfirmRequest,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour confirmer une réservation après paiement réussi.
    
    Flux:
    1. Paiement effectué et réussi dans le Payment Service
    2. Confirmation de la réservation avec l'UUID du paiement
    3. Statut passe de PENDING à CONFIRMED
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/confirm)
        request: BookingConfirmRequest avec payment_id
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation confirmée (status=confirmed)
    """
    
    try:
        booking = BookingService.confirm_booking(db, booking_id, request.payment_id)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la confirmation"
        )

# ============================================================================
# ENDPOINT 8 : ANNULER UNE RÉSERVATION
# ============================================================================

@router.post(
    "/{booking_id}/cancel",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Annuler une réservation",
)
def cancel_booking(
    booking_id: UUID,
    request: BookingCancelRequest,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour annuler une réservation.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/cancel)
        request: BookingCancelRequest avec la raison de l'annulation
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation annulée (status=cancelled)
    """
    
    try:
        booking = BookingService.cancel_booking(db, booking_id)
        return booking
    except ValueError as e:
        if "non trouvée" in str(e):
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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'annulation"
        )

# ============================================================================
# ENDPOINT 8b : ACCEPTER UNE RÉSERVATION (CONDUCTEUR)
# ============================================================================

@router.post(
    "/{booking_id}/accept",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Le conducteur accepte une réservation",
)
def accept_booking(
    booking_id: UUID,
    db: Session = Depends(get_db)
) -> BookingResponse:
    try:
        return BookingService.accept_booking(db, booking_id)
    except ValueError as e:
        code = status.HTTP_404_NOT_FOUND if "non trouvée" in str(e) else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=str(e))

# ============================================================================
# ENDPOINT 8c : REFUSER UNE RÉSERVATION (CONDUCTEUR)
# ============================================================================

@router.post(
    "/{booking_id}/reject",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Le conducteur refuse une réservation",
)
def reject_booking(
    booking_id: UUID,
    request: dict = None,
    db: Session = Depends(get_db)
) -> BookingResponse:
    reason = (request or {}).get("reason")
    try:
        return BookingService.reject_booking(db, booking_id, reason)
    except ValueError as e:
        code = status.HTTP_404_NOT_FOUND if "non trouvée" in str(e) else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=str(e))

# ============================================================================
# ENDPOINT 9 : MARQUER COMME COMPLÉTÉ
# ============================================================================

@router.post(
    "/{booking_id}/complete",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Marquer une réservation comme complétée",
)
def complete_booking(
    booking_id: UUID,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour marquer une réservation comme complétée (trajet terminé).
    Appelé par le conducteur après avoir déposé le passager.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/complete)
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation complétée (status=completed)
    """
    
    try:
        booking = BookingService.complete_booking(db, booking_id)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la complétion"
        )

# ============================================================================
# ENDPOINT 10 : MARQUER COMME NO-SHOW
# ============================================================================

@router.post(
    "/{booking_id}/no-show",
    response_model=BookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Marquer une réservation comme no-show (passager absent)",
)
def mark_no_show(
    booking_id: UUID,
    db: Session = Depends(get_db)
) -> BookingResponse:
    """
    Endpoint pour marquer une réservation comme "no-show" (passager absent).
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/no-show)
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingResponse: La réservation marquée no-show
    """
    
    try:
        booking = BookingService.mark_no_show(db, booking_id)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du marquage no-show"
        )

# ============================================================================
# ENDPOINT 11 : AJOUTER UNE NOTE À UNE RÉSERVATION
# ============================================================================

@router.post(
    "/{booking_id}/notes",
    response_model=BookingNoteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter une note à une réservation",
)
def add_booking_note(
    booking_id: UUID,
    request: BookingNoteCreateRequest,
    db: Session = Depends(get_db)
) -> BookingNoteResponse:
    """
    Endpoint pour ajouter une note/commentaire à une réservation.
    Utilisé par le conducteur et le passager pour communiquer.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/notes)
        request: BookingNoteCreateRequest avec author_id et text
        db: Session SQLAlchemy injectée
    
    Retour:
        BookingNoteResponse: La note créée
    """
    
    try:
        note = BookingService.add_booking_note(db, booking_id, request)
        return note
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'ajout de la note"
        )

# ============================================================================
# ENDPOINT 12 : RÉCUPÉRER LES NOTES D'UNE RÉSERVATION
# ============================================================================

@router.get(
    "/{booking_id}/notes",
    response_model=list,
    status_code=status.HTTP_200_OK,
    summary="Récupérer les notes d'une réservation",
)
def get_booking_notes(
    booking_id: UUID,
    db: Session = Depends(get_db)
) -> list:
    """
    Endpoint pour récupérer toutes les notes d'une réservation.
    
    Paramètres:
        booking_id: UUID de la réservation (dans l'URL : /{booking_id}/notes)
        db: Session SQLAlchemy injectée
    
    Retour:
        list: Liste des notes (BookingNoteResponse)
    """
    
    notes = BookingService.get_booking_notes(db, booking_id)
    return notes

# ============================================================================
# ENDPOINT 13 : OBTENIR LES STATISTIQUES
# ============================================================================

@router.get(
    "/stats/passenger/{passenger_id}",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Récupérer les statistiques d'un passager",
)
def get_passenger_stats(
    passenger_id: UUID,
    db: Session = Depends(get_db)
) -> dict:
    """
    Endpoint pour récupérer les statistiques de réservation d'un passager.
    
    Paramètres:
        passenger_id: UUID du passager (dans l'URL : /stats/passenger/{passenger_id})
        db: Session SQLAlchemy injectée
    
    Retour:
        dict: Dictionnaire avec les statistiques
    """
    
    return BookingService.get_booking_statistics(db, passenger_id=passenger_id)


# ============================================================================
# ENDPOINT : RÉCUPÉRER LE CODE D'EMBARQUEMENT (PASSAGER)
# ============================================================================

@router.get(
    "/{booking_id}/boarding-code",
    status_code=status.HTTP_200_OK,
    summary="Récupérer le code d'embarquement d'une réservation",
)
def get_boarding_code(
    booking_id: UUID,
    db: Session = Depends(get_db),
) -> dict:
    """
    Le passager appelle cet endpoint pour récupérer son code PIN 4 chiffres.
    Il peut l'afficher en texte ou sous forme de QR code.
    Disponible uniquement pour les réservations confirmées (payées).
    """
    try:
        return BookingService.get_boarding_code(db, booking_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# ============================================================================
# ENDPOINT : VÉRIFIER L'EMBARQUEMENT (CHAUFFEUR)
# ============================================================================

@router.post(
    "/{booking_id}/verify-boarding",
    response_model=BoardingResponse,
    status_code=status.HTTP_200_OK,
    summary="Vérifier l'embarquement d'un passager",
)
def verify_boarding(
    booking_id: UUID,
    request: BoardingVerifyRequest,
    db: Session = Depends(get_db),
) -> BoardingResponse:
    """
    Le chauffeur appelle cet endpoint avec le code PIN donné par le passager
    (saisi manuellement ou extrait du QR code scanné).
    Si le code est correct, le passager est marqué comme embarqué.
    """
    try:
        return BookingService.verify_boarding(db, booking_id, request)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# ============================================================================
# ENDPOINT : STATUT EMBARQUEMENT D'UN TRAJET (CHAUFFEUR)
# ============================================================================

@router.get(
    "/trip/{trip_id}/boarding-status",
    status_code=status.HTTP_200_OK,
    summary="Statut d'embarquement de tous les passagers d'un trajet",
)
def get_trip_boarding_status(
    trip_id: UUID,
    db: Session = Depends(get_db),
) -> dict:
    """
    Le chauffeur appelle cet endpoint pour voir combien de passagers
    sont vérifiés avant de démarrer le trajet.
    """
    return BookingService.get_trip_boarding_status(db, trip_id)
