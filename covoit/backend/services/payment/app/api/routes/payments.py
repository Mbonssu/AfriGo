# Import de FastAPI pour créer les endpoints
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from typing import Optional
from urllib.parse import parse_qsl
from uuid import UUID

# Import des dépendances
from app.db.session import get_db

# Import des schémas Pydantic
from app.schemas.payment import (
    MonetbilPaymentInitiateRequest,
    MonetbilPaymentInitiateResponse,
    MonetbilPaymentVerifyRequest,
    MonetbilPaymentVerifyResponse,
    PaymentCreateRequest,
    PaymentResponse,
    PaymentStatusUpdateRequest,
    PaymentSearchRequest,
    PaymentSearchResponse,
    RefundRequest,
    RefundResponse,
    ErrorResponse,
)

# Import du service métier
from app.services.payment_service import PaymentService

# Créer un routeur FastAPI pour les endpoints de paiement
# Le préfixe "/payments" sera ajouté à toutes les routes
router = APIRouter(prefix="/payments", tags=["Payments"])

# ============================================================================
# ENDPOINT 1 : CRÉER UN PAIEMENT
# ============================================================================

@router.post(
    "",
    response_model=PaymentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un nouveau paiement",
    responses={
        201: {"description": "Paiement créé avec succès"},
        400: {"description": "Données invalides"},
        500: {"description": "Erreur serveur"},
    }
)
def create_payment(
    request: PaymentCreateRequest,
    db: Session = Depends(get_db)
) -> PaymentResponse:
    """
    Endpoint pour créer un nouveau paiement MTN ou Orange Money.
    
    Flux:
    1. Valider les données du paiement (montant > 0, user_id valide)
    2. Créer le paiement en base de données avec statut PENDING
    3. Retourner les données du paiement créé
    4. (Plus tard) Appeler l'API du prestataire (MTN/Orange Money)
    
    Paramètres:
        request: Objet PaymentCreateRequest avec:
        - user_id: UUID de l'utilisateur
        - amount: Montant en FCFA
        - payment_method: "mtn" ou "orange"
        - payment_type: "booking", "caution" ou "subscription"
        - phone_number: Numéro de téléphone
        
        db: Session SQLAlchemy injectée par Depends(get_db)
    
    Retour:
        PaymentResponse: Le paiement créé avec son UUID et timestamps
    
    Exemple de requête:
    POST /api/v1/payments/
    {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "booking_id": "550e8400-e29b-41d4-a716-446655440001",
        "amount": 5000.0,
        "payment_method": "mtn",
        "payment_type": "booking",
        "phone_number": "+237655123456"
    }
    
    Réponse (201):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "booking_id": "550e8400-e29b-41d4-a716-446655440001",
        "amount": 5000.0,
        "payment_method": "mtn",
        "payment_type": "booking",
        "phone_number": "+237655123456",
        "status": "pending",
        "transaction_id": null,
        "created_at": "2024-01-15T10:30:00",
        "updated_at": "2024-01-15T10:30:00"
    }
    """
    
    # Appeler le service pour créer le paiement
    try:
        payment = PaymentService.create_payment(db, request)
        return payment
    
    # Gérer les erreurs de validation
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    # Gérer les erreurs inattendues
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la création du paiement"
        )

# ============================================================================
# ENDPOINT 2 : INITIER UN PAIEMENT MONETBIL
# ============================================================================

@router.post(
    "/initiate",
    response_model=MonetbilPaymentInitiateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un paiement local et déclencher Monetbil",
)
def initiate_monetbil_payment(
    request: MonetbilPaymentInitiateRequest,
    db: Session = Depends(get_db),
) -> MonetbilPaymentInitiateResponse:
    try:
        return PaymentService.initiate_monetbil_payment(db, request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'initialisation du paiement Monetbil",
        )

# ============================================================================
# ENDPOINT 3 : VÉRIFIER UN PAIEMENT MONETBIL
# ============================================================================

@router.post(
    "/verify",
    response_model=MonetbilPaymentVerifyResponse,
    status_code=status.HTTP_200_OK,
    summary="Vérifier le statut réel d'un paiement Monetbil",
)
def verify_monetbil_payment(
    request: MonetbilPaymentVerifyRequest,
    db: Session = Depends(get_db),
) -> MonetbilPaymentVerifyResponse:
    try:
        return PaymentService.verify_monetbil_payment(db, request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la verification du paiement Monetbil",
        )

# ============================================================================
# ENDPOINT 4 : HISTORIQUE DES PAIEMENTS
# ============================================================================

@router.get(
    "/history",
    response_model=PaymentSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer l'historique de paiement d'un utilisateur",
)
def get_payment_history(
    user_id: UUID,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
) -> PaymentSearchResponse:
    if limit > 100:
        limit = 100
    if limit < 1:
        limit = 1
    if offset < 0:
        offset = 0

    return PaymentService.get_user_payments(db, user_id, limit, offset)

# ============================================================================
# ENDPOINT 5 : CALLBACK MONETBIL
# ============================================================================

@router.api_route(
    "/notify/monetbil",
    methods=["GET", "POST"],
    response_model=MonetbilPaymentVerifyResponse,
    status_code=status.HTTP_200_OK,
    summary="Recevoir une notification serveur Monetbil",
)
async def monetbil_notification(
    request: Request,
    db: Session = Depends(get_db),
) -> MonetbilPaymentVerifyResponse:
    try:
        if request.method == "GET":
            payload = dict(request.query_params)
        else:
            try:
                payload = await request.json()
            except Exception:
                raw_body = (await request.body()).decode()
                payload = dict(parse_qsl(raw_body))

        return PaymentService.handle_monetbil_notification(db, dict(payload))
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du traitement de la notification Monetbil",
        )

# ============================================================================
# ENDPOINT 6 : RÉCUPÉRER UN PAIEMENT PAR ID
# ============================================================================

@router.get(
    "/{payment_id}",
    response_model=PaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer un paiement par son ID",
    responses={
        200: {"description": "Paiement trouvé"},
        404: {"description": "Paiement non trouvé"},
    }
)
def get_payment(
    payment_id: UUID,
    db: Session = Depends(get_db)
) -> PaymentResponse:
    """
    Endpoint pour récupérer les détails complets d'un paiement.
    
    Paramètres:
        payment_id: UUID du paiement à récupérer (dans l'URL : /{payment_id})
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentResponse: Les détails complets du paiement
    
    Lève HTTPException(404) si le paiement n'existe pas
    
    Exemple de requête:
    GET /api/v1/payments/550e8400-e29b-41d4-a716-446655440002
    
    Réponse (200):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "amount": 5000.0,
        "payment_method": "mtn",
        "status": "success",
        "transaction_id": "TXN123456789",
        "created_at": "2024-01-15T10:30:00",
        "updated_at": "2024-01-15T10:35:00"
    }
    """
    
    # Récupérer le paiement via le service
    payment = PaymentService.get_payment_by_id(db, payment_id)
    
    # Vérifier que le paiement existe
    if payment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Paiement {payment_id} non trouvé"
        )
    
    # Retourner le paiement
    return payment

# ============================================================================
# ENDPOINT 7 : RECHERCHER LES PAIEMENTS D'UN UTILISATEUR
# ============================================================================

@router.get(
    "/user/{user_id}",
    response_model=PaymentSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Récupérer tous les paiements d'un utilisateur",
)
def get_user_payments(
    user_id: UUID,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db)
) -> PaymentSearchResponse:
    """
    Endpoint pour récupérer tous les paiements d'un utilisateur avec pagination.
    
    Paramètres:
        user_id: UUID de l'utilisateur (dans l'URL : /user/{user_id})
        limit: Nombre de résultats par page (défaut 20, max 100)
        offset: Position de départ pour la pagination (défaut 0)
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentSearchResponse: Liste paginée des paiements
    
    Exemple de requête:
    GET /api/v1/payments/user/550e8400-e29b-41d4-a716-446655440000?limit=10&offset=0
    
    Réponse (200):
    {
        "data": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440002",
                "user_id": "550e8400-e29b-41d4-a716-446655440000",
                "amount": 5000.0,
                "status": "success",
                ...
            }
        ],
        "total": 42,
        "count": 10,
        "offset": 0,
        "limit": 10
    }
    """
    
    # Valider les paramètres de pagination
    if limit > 100:
        limit = 100
    if limit < 1:
        limit = 1
    if offset < 0:
        offset = 0
    
    # Appeler le service pour récupérer les paiements
    return PaymentService.get_user_payments(db, user_id, limit, offset)

# ============================================================================
# ENDPOINT 8 : RECHERCHER LES PAIEMENTS AVEC FILTRES
# ============================================================================

@router.post(
    "/search",
    response_model=PaymentSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Rechercher les paiements avec filtres",
)
def search_payments(
    request: PaymentSearchRequest,
    db: Session = Depends(get_db)
) -> PaymentSearchResponse:
    """
    Endpoint pour rechercher les paiements avec filtres multiples.
    
    Filtres disponibles:
    - user_id: UUID de l'utilisateur
    - status: "pending", "success", "failed", "cancelled", "refunded"
    - payment_type: "booking", "caution", "subscription"
    - payment_method: "mtn", "orange"
    - min_amount / max_amount: Plage de montants
    
    Paramètres:
        request: Objet PaymentSearchRequest avec les critères de recherche
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentSearchResponse: Résultats filtrés et paginés
    
    Exemple de requête:
    POST /api/v1/payments/search
    {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "success",
        "payment_method": "mtn",
        "min_amount": 1000,
        "max_amount": 10000,
        "limit": 20,
        "offset": 0
    }
    
    Réponse (200):
    {
        "data": [...],
        "total": 3,
        "count": 3,
        "offset": 0,
        "limit": 20
    }
    """
    
    # Appeler le service pour effectuer la recherche
    return PaymentService.search_payments(db, request)

# ============================================================================
# ENDPOINT 9 : METTRE À JOUR LE STATUT D'UN PAIEMENT
# ============================================================================

@router.put(
    "/{payment_id}/status",
    response_model=PaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Mettre à jour le statut d'un paiement",
)
def update_payment_status(
    payment_id: UUID,
    request: PaymentStatusUpdateRequest,
    db: Session = Depends(get_db)
) -> PaymentResponse:
    """
    Endpoint pour mettre à jour le statut d'un paiement.
    Appelé lorsqu'on reçoit une notification du prestataire (MTN/Orange Money).
    
    Flux:
    1. Valider que le paiement existe
    2. Mettre à jour le statut dans la base de données
    3. Enregistrer la réponse du prestataire dans l'historique
    4. Retourner le paiement mis à jour
    
    Paramètres:
        payment_id: UUID du paiement (dans l'URL : /{payment_id}/status)
        request: PaymentStatusUpdateRequest avec:
        - status: Nouveau statut ("success", "failed", etc.)
        - transaction_id: ID du prestataire (optionnel)
        - provider_response: Réponse JSON du prestataire (optionnel)
        
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentResponse: Le paiement mit à jour
    
    Lève HTTPException(404) si le paiement n'existe pas
    
    Exemple de requête:
    PUT /api/v1/payments/550e8400-e29b-41d4-a716-446655440002/status
    {
        "status": "success",
        "transaction_id": "TXN123456789",
        "provider_response": "{\"status\": \"SUCCESSFUL\", \"transactionId\": \"TXN123456789\"}"
    }
    
    Réponse (200):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "status": "success",
        "transaction_id": "TXN123456789",
        "updated_at": "2024-01-15T10:35:00",
        ...
    }
    """
    
    # Appeler le service pour mettre à jour le statut
    try:
        payment = PaymentService.update_payment_status(db, payment_id, request)
        return payment
    
    # Gérer le cas où le paiement n'existe pas
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    
    # Gérer les erreurs inattendues
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour du paiement"
        )

# ============================================================================
# ENDPOINT 10 : ANNULER UN PAIEMENT
# ============================================================================

@router.post(
    "/{payment_id}/cancel",
    response_model=PaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Annuler un paiement",
)
def cancel_payment(
    payment_id: UUID,
    db: Session = Depends(get_db)
) -> PaymentResponse:
    """
    Endpoint pour annuler un paiement en attente.
    Utilisé quand l'utilisateur annule sa réservation avant la confirmation du paiement.
    
    Validations:
    - Le paiement doit exister
    - Le paiement ne doit pas être déjà réussi (sinon demander un remboursement)
    
    Paramètres:
        payment_id: UUID du paiement à annuler (dans l'URL : /{payment_id}/cancel)
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentResponse: Le paiement annulé (status = "cancelled")
    
    Lève HTTPException(404) si le paiement n'existe pas
    Lève HTTPException(400) si le paiement ne peut pas être annulé
    
    Exemple de requête:
    POST /api/v1/payments/550e8400-e29b-41d4-a716-446655440002/cancel
    
    Réponse (200):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "status": "cancelled",
        "updated_at": "2024-01-15T10:35:00",
        ...
    }
    """
    
    # Appeler le service pour annuler le paiement
    try:
        payment = PaymentService.cancel_payment(db, payment_id)
        return payment
    
    # Gérer les erreurs de validation
    except ValueError as e:
        # Si le paiement n'existe pas
        if "non trouvé" in str(e):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        # Si le paiement ne peut pas être annulé
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e)
            )
    
    # Gérer les erreurs inattendues
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'annulation du paiement"
        )

# ============================================================================
# ENDPOINT 11 : REMBOURSER UN PAIEMENT
# ============================================================================

@router.post(
    "/{payment_id}/refund",
    response_model=PaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Rembourser un paiement",
)
def refund_payment(
    payment_id: UUID,
    request: RefundRequest,
    db: Session = Depends(get_db)
) -> PaymentResponse:
    """
    Endpoint pour rembourser un paiement réussi.
    Utilisé après une transaction réussie si l'utilisateur annule ou en cas de problème.
    
    Validations:
    - Le paiement doit exister
    - Le paiement doit avoir un statut SUCCESS
    - Le montant partiel ne doit pas dépasser le montant total
    
    Paramètres:
        payment_id: UUID du paiement à rembourser (dans l'URL : /{payment_id}/refund)
        request: RefundRequest avec:
        - reason: Raison du remboursement (texte)
        - partial_amount: Montant du remboursement partiel (optionnel, null = complet)
        
        db: Session SQLAlchemy injectée
    
    Retour:
        PaymentResponse: Le paiement avec status = "refunded"
    
    Lève HTTPException(404) si le paiement n'existe pas ou n'est pas réussi
    Lève HTTPException(400) si validation échoue
    
    Exemple de requête:
    POST /api/v1/payments/550e8400-e29b-41d4-a716-446655440002/refund
    {
        "reason": "Utilisateur a annulé sa réservation",
        "partial_amount": null
    }
    
    Réponse (200):
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "status": "refunded",
        "amount": 5000.0,
        "updated_at": "2024-01-15T10:40:00",
        ...
    }
    """
    
    # Appeler le service pour rembourser
    try:
        payment, success = PaymentService.refund_payment(db, payment_id, request)
        return payment
    
    # Gérer les erreurs de validation
    except ValueError as e:
        error_str = str(e)
        
        # Si le paiement n'existe pas
        if "non trouvé" in error_str:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error_str
            )
        # Autres erreurs de validation
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_str
            )
    
    # Gérer les erreurs inattendues
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du remboursement du paiement"
        )

# ============================================================================
# ENDPOINT 8 : OBTENIR LES STATISTIQUES DE PAIEMENT
# ============================================================================

@router.get(
    "/stats/user/{user_id}",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Récupérer les statistiques de paiement d'un utilisateur",
)
def get_user_payment_stats(
    user_id: UUID,
    db: Session = Depends(get_db)
) -> dict:
    """
    Endpoint pour récupérer les statistiques sur les paiements d'un utilisateur.
    Utile pour afficher des graphiques et rapports dans l'interface.
    
    Statistiques retournées:
    - total_amount: Somme totale payée
    - total_count: Nombre total de paiements
    - success_count: Paiements réussis
    - failed_count: Paiements échoués
    - success_rate: Pourcentage de succès
    - average_amount: Montant moyen par paiement
    
    Paramètres:
        user_id: UUID de l'utilisateur (dans l'URL : /stats/user/{user_id})
        db: Session SQLAlchemy injectée
    
    Retour:
        dict: Dictionnaire avec les statistiques
    
    Exemple de requête:
    GET /api/v1/payments/stats/user/550e8400-e29b-41d4-a716-446655440000
    
    Réponse (200):
    {
        "total_amount": 50000.0,
        "total_count": 5,
        "success_count": 4,
        "failed_count": 1,
        "pending_count": 0,
        "cancelled_count": 0,
        "refunded_count": 0,
        "success_rate": 80.0,
        "average_amount": 10000.0
    }
    """
    
    # Appeler le service pour récupérer les statistiques
    return PaymentService.get_payment_statistics(db, user_id=user_id)
