# Import de Pydantic pour la validation des données
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime
from enum import Enum
from uuid import UUID

# Énumérations mirroir des modèles SQLAlchemy
class BookingStatusSchema(str, Enum):
    """Énumération des statuts de réservation pour les schémas"""
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    COMPLETED = "completed"
    NO_SHOW = "no_show"

# ============================================================================
# SCHÉMAS DE CRÉATION (Requête POST)
# ============================================================================

class BookingCreateRequest(BaseModel):
    """
    Schéma pour créer une nouvelle réservation.
    
    Exemple:
    {
        "trip_id": "550e8400-e29b-41d4-a716-446655440000",
        "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
        "number_of_seats": 2,
        "total_price": 5000.0,
        "pickup_location": "3.848,11.502",
        "dropoff_location": "3.868,11.516"
    }
    """
    
    # UUID du trajet
    trip_id: UUID = Field(..., description="UUID du trajet")
    
    # UUID du passager
    passenger_id: UUID = Field(..., description="UUID du passager")
    
    # Nombre de places
    number_of_seats: int = Field(..., ge=1, le=6, description="Nombre de places (1-6)")
    
    # Prix total
    total_price: float = Field(..., gt=0, description="Prix total en FCFA")
    
    # Localisation du rassemblement
    pickup_location: Optional[str] = Field(None, description="Lieu de rassemblement")
    
    # Localisation de dépôt
    dropoff_location: Optional[str] = Field(None, description="Lieu de dépôt")
    
    class Config:
        json_schema_extra = {
            "example": {
                "trip_id": "550e8400-e29b-41d4-a716-446655440000",
                "passenger_id": "550e8400-e29b-41d4-a716-446655440001",
                "number_of_seats": 2,
                "total_price": 5000.0,
                "pickup_location": "3.848,11.502",
                "dropoff_location": "3.868,11.516"
            }
        }

# Schéma pour mettre à jour une réservation
class BookingUpdateRequest(BaseModel):
    """
    Schéma pour mettre à jour une réservation.
    Seul le statut et les notes du conducteur peuvent être modifiés.
    """
    
    # Nouveau statut
    status: Optional[BookingStatusSchema] = Field(None, description="Nouveau statut")
    
    # Notes du conducteur
    driver_notes: Optional[str] = Field(None, max_length=500, description="Notes du conducteur")

# ============================================================================
# SCHÉMAS DE RÉPONSE
# ============================================================================

class BookingResponse(BaseModel):
    """
    Schéma de réponse complète pour une réservation.
    """
    
    # Identifiant unique
    id: UUID = Field(..., description="UUID de la réservation")
    
    # Trajet associé
    trip_id: UUID = Field(..., description="UUID du trajet")
    
    # Passager
    passenger_id: UUID = Field(..., description="UUID du passager")
    
    # Nombre de places
    number_of_seats: int = Field(..., description="Nombre de places")
    
    # Prix total
    total_price: float = Field(..., description="Prix total en FCFA")
    
    # Statut
    status: BookingStatusSchema = Field(..., description="Statut de la réservation")
    
    # Picking location
    pickup_location: Optional[str] = Field(None, description="Lieu de rassemblement")
    
    # Dropoff location
    dropoff_location: Optional[str] = Field(None, description="Lieu de dépôt")
    
    # Paiement associé
    payment_id: Optional[UUID] = Field(None, description="UUID du paiement")
    
    # Notes du conducteur
    driver_notes: Optional[str] = Field(None, description="Notes du conducteur")

    # Boarding / vérification embarquement
    boarding_code: Optional[str] = Field(None, description="Code PIN 4 chiffres d'embarquement")
    is_boarded: bool = Field(False, description="Passager vérifié à l'embarquement")
    boarded_at: Optional[datetime] = Field(None, description="Date/heure vérification embarquement")
    boarding_method: Optional[str] = Field(None, description="Méthode vérification: pin ou qr")
    
    # Timestamps
    created_at: datetime = Field(..., description="Date de création")
    updated_at: datetime = Field(..., description="Date de dernière modification")
    
    class Config:
        from_attributes = True

# ============================================================================
# SCHÉMAS DE RECHERCHE
# ============================================================================

class BookingSearchRequest(BaseModel):
    """
    Schéma pour rechercher des réservations avec filtres.
    """
    
    # Filtrer par trajet
    trip_id: Optional[UUID] = Field(None, description="UUID du trajet")
    
    # Filtrer par passager
    passenger_id: Optional[UUID] = Field(None, description="UUID du passager")
    
    # Filtrer par statut
    status: Optional[BookingStatusSchema] = Field(None, description="Statut à filtrer")
    
    # Filtrer par prix minimum
    min_price: Optional[float] = Field(None, ge=0, description="Prix minimum")
    
    # Filtrer par prix maximum
    max_price: Optional[float] = Field(None, ge=0, description="Prix maximum")
    
    # Pagination
    limit: int = Field(20, ge=1, le=100, description="Nombre de résultats")
    offset: int = Field(0, ge=0, description="Décalage")
    
    class Config:
        json_schema_extra = {
            "example": {
                "trip_id": "550e8400-e29b-41d4-a716-446655440000",
                "status": "confirmed",
                "limit": 20,
                "offset": 0
            }
        }

# Schéma pour la réponse de recherche
class BookingSearchResponse(BaseModel):
    """
    Schéma de retour pour une recherche de réservations.
    """
    
    # Liste des réservations
    data: List[BookingResponse] = Field(..., description="Liste des réservations")
    
    # Nombre total
    total: int = Field(..., ge=0, description="Nombre total de réservations")
    
    # Nombre retourné
    count: int = Field(..., ge=0, description="Nombre de résultats dans cette page")
    
    # Décalage
    offset: int = Field(..., ge=0, description="Décalage utilisé")
    
    # Limite
    limit: int = Field(..., ge=1, description="Limite utilisée")

# ============================================================================
# SCHÉMAS DE CONFIRMATION ET STATUT
# ============================================================================

class BookingConfirmRequest(BaseModel):
    """
    Schéma pour confirmer une réservation (après paiement).
    """
    
    # UUID du paiement effectué
    payment_id: UUID = Field(..., description="UUID du paiement")

class BookingCancelRequest(BaseModel):
    """
    Schéma pour annuler une réservation.
    """
    
    # Raison de l'annulation
    reason: str = Field(..., min_length=5, max_length=500, description="Raison de l'annulation")

# ============================================================================
# SCHÉMAS DE NOTES
# ============================================================================

class BookingNoteCreateRequest(BaseModel):
    """
    Schéma pour ajouter une note à une réservation.
    """
    
    # UUID de l'auteur
    author_id: UUID = Field(..., description="UUID de celui qui écrit la note")
    
    # Contenu de la note
    text: str = Field(..., min_length=1, max_length=1000, description="Contenu de la note")

class BookingNoteResponse(BaseModel):
    """
    Schéma de réponse pour une note de réservation.
    """
    
    # Identifiant
    id: UUID = Field(..., description="UUID de la note")
    
    # Réservation associée
    booking_id: UUID = Field(..., description="UUID de la réservation")
    
    # Auteur
    author_id: UUID = Field(..., description="UUID de l'auteur")
    
    # Texte
    text: str = Field(..., description="Contenu de la note")
    
    # Timestamp
    created_at: datetime = Field(..., description="Date de création")
    
    class Config:
        from_attributes = True

# ============================================================================
# SCHÉMAS D'ERREUR
# ============================================================================

class ErrorResponse(BaseModel):
    """
    Schéma standardisé pour les réponses d'erreur.
    """
    
    # Message d'erreur
    detail: str = Field(..., description="Description de l'erreur")
    
    # Code d'erreur
    code: str = Field(..., description="Code d'erreur unique")
    
    # Code HTTP
    status_code: int = Field(..., description="Code HTTP de la réponse")


# ============================================================================
# SCHÉMAS DE VÉRIFICATION EMBARQUEMENT (BOARDING)
# ============================================================================

class BoardingVerifyRequest(BaseModel):
    """
    Schéma pour la vérification d'embarquement par le chauffeur.
    Le chauffeur saisit le code PIN donné oralement par le passager,
    ou scanne le QR code du passager.
    """
    code: str = Field(..., min_length=4, max_length=4, pattern=r'^\d{4}$', description="Code PIN 4 chiffres")
    method: Literal["pin", "qr"] = Field("pin", description="Méthode: pin ou qr")


class BoardingResponse(BaseModel):
    """Réponse après une vérification d'embarquement."""
    booking_id: UUID
    passenger_id: UUID
    is_boarded: bool
    boarded_at: Optional[datetime] = None
    boarding_method: Optional[str] = None
    message: str
