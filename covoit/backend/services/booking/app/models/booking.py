# Import datetime pour gérer les timestamps
from datetime import datetime

# Import de uuid pour générer les identifiants uniques
import uuid

# Import de random + string pour générer les codes PIN
import random
import string

# Import de Enum pour les énumérations
from enum import Enum

# Import de sqlalchemy pour créer les modèles ORM
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base

# Créer la classe de base pour tous les modèles SQLAlchemy
Base = declarative_base()

# Énumération pour le statut d'une réservation
class BookingStatus(str, Enum):
    """
    Énumération des statuts possibles d'une réservation:
    - PENDING: En attente de confirmation/paiement
    - CONFIRMED: Confirmée et payée
    - CANCELLED: Annulée par le passager
    - COMPLETED: Le trajet est terminé
    - NO_SHOW: Le passager n'est pas venu
    """
    PENDING = "pending"           # En attente de confirmation
    ACCEPTED = "accepted"         # Acceptée par le conducteur
    REJECTED = "rejected"         # Refusée par le conducteur
    CONFIRMED = "confirmed"       # Confirmée (payée)
    CANCELLED = "cancelled"       # Annulée
    COMPLETED = "completed"       # Trajet terminé
    NO_SHOW = "no_show"          # Passager absent

# Modèle SQLAlchemy pour une réservation
class Booking(Base):
    """
    Modèle représentant une réservation de trajet par un passager.
    
    Attributs:
        id: Identifiant unique UUID de la réservation
        trip_id: UUID du trajet réservé
        passenger_id: UUID du passager qui réserve
        number_of_seats: Nombre de places réservées
        total_price: Prix total de la réservation
        status: Statut de la réservation (pending, confirmed, cancelled, etc.)
        pickup_location: Localisation du rassemblement du passager (optionnel)
        dropoff_location: Localisation de dépôt du passager (optionnel)
        payment_id: UUID du paiement associé (optionnel)
        driver_notes: Notes du conducteur pour ce passager (optionnel)
        created_at: Timestamp de création de la réservation
        updated_at: Timestamp de dernière modification
    """
    
    # Nom de la table en base de données
    __tablename__ = "bookings"
    
    # Colonne ID : identifiant unique de type UUID, clé primaire
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique de la réservation (UUID)"
    )
    
    # Colonne TRIPID : UUID du trajet réservé
    trip_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        index=True,  # Index pour recherches rapides par trajet
        comment="UUID du trajet réservé"
    )
    
    # Colonne PASSENGERID : UUID du passager
    passenger_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        index=True,  # Index pour recherches rapides par passager
        comment="UUID du passager qui réserve"
    )
    
    # Colonne NUMBEROFSEATS : Nombre de places réservées
    number_of_seats = Column(
        Integer,
        nullable=False,
        comment="Nombre de places réservées (1-4 généralement)"
    )
    
    # Colonne TOTALPRICE : Prix total de la réservation en FCFA
    total_price = Column(
        Float,
        nullable=False,
        comment="Prix total de la réservation en FCFA"
    )
    
    # Colonne STATUS : Énumération du statut de la réservation
    status = Column(
        SQLEnum(BookingStatus, native_enum=False),
        default=BookingStatus.PENDING,
        nullable=False,
        index=True,  # Index pour filtrer par statut
        comment="Statut de la réservation (pending/confirmed/cancelled/completed/no_show)"
    )
    
    # Colonne PICKUPLOCATION : Localisation du rassemblement
    # Format: "latitude,longitude" ou adresse textuelle
    pickup_location = Column(
        String(255),
        nullable=True,
        comment="Lieu de rassemblement du passager (lat,lon ou adresse)"
    )
    
    # Colonne DROPOFFLOCATION : Localisation de dépôt
    dropoff_location = Column(
        String(255),
        nullable=True,
        comment="Lieu de dépôt du passager (lat,lon ou adresse)"
    )
    
    # Colonne PAYMENTID : UUID du paiement associé
    payment_id = Column(
        UUID(as_uuid=True),
        nullable=True,
        index=True,  # Index pour lier à un paiement
        comment="UUID du paiement associé à cette réservation"
    )
    
    # Colonne DRIVERNOTES : Notes du conducteur
    driver_notes = Column(
        String(500),
        nullable=True,
        comment="Notes ou instructions du conducteur pour ce passager"
    )

    # ── Colonnes de vérification d'embarquement (boarding) ──────────────────
    # Code PIN 4 chiffres généré à la confirmation du paiement
    boarding_code = Column(
        String(4),
        nullable=True,
        comment="Code PIN 4 chiffres pour vérification embarquement"
    )

    # Est-ce que le passager a été vérifié (embarqué) ?
    is_boarded = Column(
        Boolean,
        default=False,
        nullable=False,
        comment="True si le passager a été vérifié à l'embarquement"
    )

    # Timestamp de la vérification
    boarded_at = Column(
        DateTime,
        nullable=True,
        comment="Date/heure de vérification embarquement"
    )

    # Méthode utilisée pour la vérification (pin ou qr)
    boarding_method = Column(
        String(10),
        nullable=True,
        comment="Méthode de vérification: pin ou qr"
    )
    # ── Fin colonnes boarding ───────────────────────────────────────────────
    
    # Colonne CREATEDAT : Timestamp de création
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de création de la réservation"
    )
    
    # Colonne UPDATEDAT : Timestamp de dernière modification
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,  # Mise à jour auto lors du UPDATE
        nullable=False,
        comment="Date et heure de dernière modification"
    )
    
    # Méthode pour convertir l'objet en dictionnaire
    def to_dict(self):
        """Convertit l'objet Booking en dictionnaire"""
        return {
            "id": str(self.id),
            "trip_id": str(self.trip_id),
            "passenger_id": str(self.passenger_id),
            "number_of_seats": self.number_of_seats,
            "total_price": self.total_price,
            "status": self.status.value,
            "pickup_location": self.pickup_location,
            "dropoff_location": self.dropoff_location,
            "payment_id": str(self.payment_id) if self.payment_id else None,
            "driver_notes": self.driver_notes,
            "boarding_code": self.boarding_code,
            "is_boarded": self.is_boarded,
            "boarded_at": self.boarded_at.isoformat() if self.boarded_at else None,
            "boarding_method": self.boarding_method,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }

    @staticmethod
    def generate_boarding_code() -> str:
        """Génère un code PIN aléatoire de 4 chiffres."""
        return ''.join(random.choices(string.digits, k=4))

# Modèle SQLAlchemy pour les commentaires/notes de réservation
class BookingNote(Base):
    """
    Modèle pour stocker les notes/commentaires d'une réservation.
    Utile pour tracker les communications conducteur-passager.
    
    Attributs:
        id: Identifiant unique
        booking_id: FK vers Booking.id
        author_id: UUID de l'auteur (conducteur ou passager)
        text: Contenu de la note
        created_at: Timestamp
    """
    
    # Nom de la table en base de données
    __tablename__ = "booking_notes"
    
    # Colonne ID
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique de la note"
    )
    
    # Colonne BOOKINGID : Clé étrangère vers Booking
    booking_id = Column(
        UUID(as_uuid=True),
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="UUID de la réservation"
    )
    
    # Colonne AUTHORID : UUID de celui qui a écrit la note
    author_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        comment="UUID de l'auteur (conducteur ou passager)"
    )
    
    # Colonne TEXT : Contenu de la note
    text = Column(
        String(1000),
        nullable=False,
        comment="Contenu de la note"
    )
    
    # Colonne CREATEDAT : Timestamp
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de la note"
    )
