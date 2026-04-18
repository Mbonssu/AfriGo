# Import de Pydantic pour la validation des données
import re
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from enum import Enum
from uuid import UUID


CM_PHONE_REGEX = re.compile(r"^(?:\+?237)?[6-9]\d{8}$")
MAX_PAYMENT_AMOUNT = 1_000_000.0

# Énumérations mirroir des modèles SQLAlchemy
class PaymentStatusSchema(str, Enum):
    """Énumération des statuts de paiement pour les schémas"""
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"

class PaymentMethodSchema(str, Enum):
    """Énumération des méthodes de paiement pour les schémas"""
    MTN = "mtn"
    ORANGE = "orange"

class PaymentTypeSchema(str, Enum):
    """Énumération des types de paiement pour les schémas"""
    BOOKING = "booking"
    CAUTION = "caution"
    SUBSCRIPTION = "subscription"

# ============================================================================
# SCHÉMAS DE CRÉATION (Requête POST)
# ============================================================================

class PaymentCreateRequest(BaseModel):
    """
    Schéma pour créer un nouveau paiement.
    
    Exemple:
    {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "booking_id": "550e8400-e29b-41d4-a716-446655440001",
        "amount": 5000.0,
        "payment_method": "mtn",
        "payment_type": "booking",
        "phone_number": "+237655123456"
    }
    """
    
    # UUID de l'utilisateur qui paie
    user_id: UUID = Field(..., description="UUID de l'utilisateur")
    
    # UUID optionnel de la réservation associée
    booking_id: Optional[UUID] = Field(None, description="UUID de la réservation (optionnel)")
    
    # Montant du paiement en FCFA
    amount: float = Field(..., gt=0, le=MAX_PAYMENT_AMOUNT, description="Montant en FCFA")
    
    # Méthode de paiement
    payment_method: PaymentMethodSchema = Field(..., description="mtn ou orange")
    
    # Type de paiement
    payment_type: PaymentTypeSchema = Field(..., description="booking, caution, ou subscription")
    
    # Numéro de téléphone
    phone_number: str = Field(..., min_length=9, max_length=20, description="Numéro de téléphone")

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, value: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", value)
        if not CM_PHONE_REGEX.match(cleaned):
            raise ValueError("Numero de telephone invalide (format Cameroun attendu)")
        return cleaned
    
    # Configuration Pydantic
    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "550e8400-e29b-41d4-a716-446655440000",
                "booking_id": "550e8400-e29b-41d4-a716-446655440001",
                "amount": 5000.0,
                "payment_method": "mtn",
                "payment_type": "booking",
                "phone_number": "+237655123456"
            }
        }


class MonetbilPaymentInitiateRequest(BaseModel):
    """Requête d'initiation d'un paiement Monetbil."""

    user_id: UUID = Field(..., description="UUID de l'utilisateur qui paie")
    booking_id: Optional[UUID] = Field(None, description="UUID de la réservation liée")
    amount: float = Field(..., gt=0, le=MAX_PAYMENT_AMOUNT, description="Montant en FCFA")
    payment_method: PaymentMethodSchema = Field(..., description="mtn ou orange")
    payment_type: PaymentTypeSchema = Field(..., description="booking, caution, subscription")
    phone_number: str = Field(..., min_length=9, max_length=20, description="Numéro Mobile Money")
    description: Optional[str] = Field(None, description="Description visible côté app")
    first_name: Optional[str] = Field(None, description="Prénom utilisateur")
    last_name: Optional[str] = Field(None, description="Nom utilisateur")
    email: Optional[str] = Field(None, description="Email utilisateur")

    @field_validator("phone_number")
    @classmethod
    def validate_momo_phone_number(cls, value: str) -> str:
        cleaned = re.sub(r"[\s\-\(\)]", "", value)
        if not CM_PHONE_REGEX.match(cleaned):
            raise ValueError("Numero Mobile Money invalide (format Cameroun attendu)")
        return cleaned


class MonetbilPaymentInitiateResponse(BaseModel):
    """Réponse de création + lancement d'une demande Monetbil."""

    payment_id: UUID = Field(..., description="UUID interne du paiement")
    provider: str = Field(default="monetbil", description="Prestataire utilisé")
    provider_payment_id: str = Field(..., description="Identifiant paymentId renvoyé par Monetbil")
    status: PaymentStatusSchema = Field(..., description="Statut applicatif local")
    provider_status: str = Field(..., description="Statut brut Monetbil")
    message: str = Field(..., description="Message à afficher à l'utilisateur")
    amount: float = Field(..., description="Montant demandé")
    payment_method: PaymentMethodSchema = Field(..., description="Méthode choisie")
    payment_type: PaymentTypeSchema = Field(..., description="Type de paiement")
    phone_number: str = Field(..., description="Numéro utilisé")
    channel_name: Optional[str] = Field(None, description="Nom du canal Monetbil")
    channel_ussd: Optional[str] = Field(None, description="Code USSD opérateur")
    operator_code: Optional[str] = Field(None, description="Code opérateur Monetbil")
    payment_url: Optional[str] = Field(None, description="URL de paiement éventuelle")


class MonetbilPaymentVerifyRequest(BaseModel):
    """Requête de vérification d'un paiement Monetbil."""

    payment_id: UUID = Field(..., description="UUID interne du paiement")


class MonetbilPaymentVerifyResponse(BaseModel):
    """Statut applicatif après interrogation de Monetbil."""

    payment_id: UUID = Field(..., description="UUID interne du paiement")
    provider: str = Field(default="monetbil", description="Prestataire utilisé")
    provider_payment_id: Optional[str] = Field(None, description="paymentId Monetbil")
    status: PaymentStatusSchema = Field(..., description="Statut local")
    provider_status: str = Field(..., description="Statut brut Monetbil")
    is_final: bool = Field(..., description="Indique si le paiement est final")
    message: str = Field(..., description="Message de suivi")
    operator_transaction_id: Optional[str] = Field(
        None,
        description="Identifiant opérateur/transaction finale quand disponible",
    )
    payment_url: Optional[str] = Field(None, description="URL de paiement éventuelle")

# Schéma pour mettre à jour le statut d'un paiement
class PaymentStatusUpdateRequest(BaseModel):
    """
    Schéma pour mettre à jour le statut d'un paiement.
    Utilé lorsqu'on reçoit une notification du prestataire (MTN/Orange).
    
    Exemple:
    {
        "status": "success",
        "transaction_id": "TXN123456789",
        "provider_response": "{...}"
    }
    """
    
    # Nouveau statut
    status: PaymentStatusSchema = Field(..., description="Nouveau statut du paiement")
    
    # ID de transaction du prestataire
    transaction_id: Optional[str] = Field(None, description="ID unique du prestataire")
    
    # Réponse du prestataire (stockée pour l'audit)
    provider_response: Optional[str] = Field(None, description="Réponse JSON du prestataire")
    
    class Config:
        json_schema_extra = {
            "example": {
                "status": "success",
                "transaction_id": "TXN123456789",
                "provider_response": '{"status": "SUCCESSFUL", "transactionId": "TXN123456789"}'
            }
        }

# ============================================================================
# SCHÉMAS DE RÉPONSE
# ============================================================================

class PaymentResponse(BaseModel):
    """
    Schéma de réponse complète pour un paiement.
    Retourné après création ou lecture d'un paiement.
    """
    
    # Identifiant unique
    id: UUID = Field(..., description="UUID du paiement")
    
    # Utilisateur
    user_id: UUID = Field(..., description="UUID du client")
    
    # Réservation associée
    booking_id: Optional[UUID] = Field(None, description="UUID de la réservation")
    
    # Montant
    amount: float = Field(..., description="Montant en FCFA")
    
    # Méthode
    payment_method: PaymentMethodSchema = Field(..., description="Méthode de paiement")
    
    # Type
    payment_type: PaymentTypeSchema = Field(..., description="Type de paiement")
    
    # Numéro
    phone_number: str = Field(..., description="Numéro de téléphone utilisé")
    
    # Statut
    status: PaymentStatusSchema = Field(..., description="Statut actuel")
    
    # ID du prestataire
    transaction_id: Optional[str] = Field(None, description="ID du prestataire")
    
    # Timestamps
    created_at: datetime = Field(..., description="Date de création")
    updated_at: datetime = Field(..., description="Date de dernière modification")
    
    # Configuration Pydantic (important pour SQLAlchemy)
    class Config:
        from_attributes = True  # Permet la conversion depuis les objets SQLAlchemy

# ============================================================================
# SCHÉMAS DE RECHERCHE
# ============================================================================

class PaymentSearchRequest(BaseModel):
    """
    Schéma pour rechercher des paiements avec filtres.
    
    Exemple:
    {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "success",
        "payment_method": "mtn",
        "limit": 20,
        "offset": 0
    }
    """
    
    # Filtrer par utilisateur
    user_id: Optional[UUID] = Field(None, description="UUID de l'utilisateur")
    
    # Filtrer par statut
    status: Optional[PaymentStatusSchema] = Field(None, description="Statut à filtrer")
    
    # Filtrer par type
    payment_type: Optional[PaymentTypeSchema] = Field(None, description="Type de paiement")
    
    # Filtrer par méthode
    payment_method: Optional[PaymentMethodSchema] = Field(None, description="Méthode de paiement")
    
    # Filtrer par montant minimum
    min_amount: Optional[float] = Field(None, ge=0, description="Montant minimum")
    
    # Filtrer par montant maximum
    max_amount: Optional[float] = Field(None, ge=0, description="Montant maximum")
    
    # Pagination : nombre de résultats
    limit: int = Field(20, ge=1, le=100, description="Nombre de résultats (max 100)")
    
    # Pagination : décalage
    offset: int = Field(0, ge=0, description="Décalage pour la pagination")
    
    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "550e8400-e29b-41d4-a716-446655440000",
                "status": "success",
                "payment_method": "mtn",
                "limit": 20,
                "offset": 0
            }
        }

# Schéma pour la réponse de recherche
class PaymentSearchResponse(BaseModel):
    """
    Schéma de retour pour une recherche de paiements.
    Inclut pagination et liste de résultats.
    """
    
    # Liste des paiements trouvés
    data: List[PaymentResponse] = Field(..., description="Liste des paiements")
    
    # Nombre total de résultats
    total: int = Field(..., ge=0, description="Nombre total de paiements")
    
    # Nombre de résultats retournés
    count: int = Field(..., ge=0, description="Nombre de résultats dans cette page")
    
    # Décalage utilisé
    offset: int = Field(..., ge=0, description="Décalage utilisé")
    
    # Limite utilisée
    limit: int = Field(..., ge=1, description="Limite utilisée")

# ============================================================================
# SCHÉMAS DE VÉRIFICATION ET STATUT
# ============================================================================

class PaymentStatusResponse(BaseModel):
    """
    Schéma simplifié pour vérifier le statut d'un paiement.
    Utilisé par les webhooks et les vérifications de statut.
    """
    
    # ID du paiement
    id: UUID = Field(..., description="UUID du paiement")
    
    # Statut actuel
    status: PaymentStatusSchema = Field(..., description="Statut du paiement")
    
    # Montant
    amount: float = Field(..., description="Montant en FCFA")
    
    # ID de transaction du prestataire
    transaction_id: Optional[str] = Field(None, description="ID du prestataire")
    
    # Dernière modification
    updated_at: datetime = Field(..., description="Dernière mise à jour")
    
    class Config:
        from_attributes = True

# ============================================================================
# SCHÉMAS D'ERREUR
# ============================================================================

class ErrorResponse(BaseModel):
    """
    Schéma standardisé pour les réponses d'erreur.
    
    Exemple:
    {
        "detail": "Paiement non trouvé",
        "code": "PAYMENT_NOT_FOUND",
        "status_code": 404
    }
    """
    
    # Message d'erreur
    detail: str = Field(..., description="Description de l'erreur")
    
    # Code d'erreur
    code: str = Field(..., description="Code d'erreur unique")
    
    # Code HTTP
    status_code: int = Field(..., description="Code HTTP de la réponse")
    
    class Config:
        json_schema_extra = {
            "example": {
                "detail": "Paiement non trouvé",
                "code": "PAYMENT_NOT_FOUND",
                "status_code": 404
            }
        }

# ============================================================================
# SCHÉMAS DE REMBOURSEMENT
# ============================================================================

class RefundRequest(BaseModel):
    """
    Schéma pour demander un remboursement.
    
    Exemple:
    {
        "reason": "Utilisateur a demandé l'annulation du trajet",
        "partial_amount": null
    }
    """
    
    # Raison du remboursement
    reason: str = Field(..., min_length=5, max_length=500, description="Raison du remboursement")
    
    # Montant partiel (optionnel, null = remboursement complet)
    partial_amount: Optional[float] = Field(None, gt=0, description="Montant du remboursement partiel")
    
    class Config:
        json_schema_extra = {
            "example": {
                "reason": "Utilisateur a annulé sa réservation",
                "partial_amount": None
            }
        }

class RefundResponse(BaseModel):
    """
    Schéma de réponse après un remboursement.
    """
    
    # ID du paiement original
    original_payment_id: UUID = Field(..., description="UUID du paiement original")
    
    # Montant remboursé
    refund_amount: float = Field(..., description="Montant remboursé en FCFA")
    
    # Statut
    status: PaymentStatusSchema = Field(..., description="Statut du remboursement")
    
    # Message
    message: str = Field(..., description="Message de confirmation")
    
    class Config:
        from_attributes = True
