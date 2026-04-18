# Import datetime pour gérer les timestamps
from datetime import datetime

# Import de uuid pour générer les identifiants uniques
import uuid

# Import de Enum pour les énumérations
from enum import Enum

# Import de sqlalchemy pour créer les modèles ORM
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base

# Créer la classe de base pour tous les modèles SQLAlchemy
Base = declarative_base()

# Énumération pour les statuts possibles d'un paiement
class PaymentStatus(str, Enum):
    """
    Énumération des statuts pour un paiement:
    - PENDING: En attente de confirmation
    - SUCCESS: Paiement réussi
    - FAILED: Paiement échoué
    - CANCELLED: Paiement annulé par l'utilisateur
    - REFUNDED: Remboursement lancé
    """
    PENDING = "pending"         # En attente
    SUCCESS = "success"         # Réussi
    FAILED = "failed"          # Échoué
    CANCELLED = "cancelled"    # Annulé
    REFUNDED = "refunded"      # Remboursé

# Énumération pour les méthodes de paiement disponibles
class PaymentMethod(str, Enum):
    """
    Énumération des méthodes de paiement disponibles:
    - MTN: MTN Mobile Money (Cameroon)
    - ORANGE: Orange Money (Cameroon)
    """
    MTN = "mtn"              # MTN Mobile Money
    ORANGE = "orange"       # Orange Money

# Énumération pour les types de paiement
class PaymentType(str, Enum):
    """
    Énumération des types de paiement:
    - BOOKING: Paiement pour une réservation de trajet
    - CAUTION: Caution de sécurité (500 FCFA par place)
    - SUBSCRIPTION: Abonnement Prime
    """
    BOOKING = "booking"          # Réservation de trajet
    CAUTION = "caution"          # Caution de sécurité
    SUBSCRIPTION = "subscription" # Abonnement Prime

# Modèle SQLAlchemy pour un paiement (table 'payments' en base de données)
class Payment(Base):
    """
    Modèle représentant un paiement effectué par un utilisateur.
    
    Attributs:
        id: Identifiant unique UUID du paiement
        user_id: UUID de l'utilisateur qui effectue le paiement
        booking_id: UUID optionnel de la réservation associée
        amount: Montant en FCFA
        payment_method: Méthode (MTN ou ORANGE)
        payment_type: Type (booking, caution, subscription)
        phone_number: Numéro de téléphone utilisé pour le paiement
        status: Statut actuel (pending, success, failed, cancelled, refunded)
        transaction_id: Identifiant unique du prestataire (MTN/Orange)
        created_at: Timestamp de création
        updated_at: Timestamp de dernière modification
    """
    
    # Nom de la table en base de données
    __tablename__ = "payments"
    
    # Colonne ID : identifiant unique de type UUID, clé primaire
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique du paiement (UUID)"
    )
    
    # Colonne USERID : UUID de l'utilisateur qui paie
    user_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        index=True,  # Index pour recherches rapides par utilisateur
        comment="UUID de l'utilisateur effectuant le paiement"
    )
    
    # Colonne BOOKINGID : Référence optionnelle à la réservation associée
    booking_id = Column(
        UUID(as_uuid=True),
        nullable=True,
        index=True,  # Index pour lier le paiement à une réservation
        comment="UUID de la réservation associée (optionnel)"
    )
    
    # Colonne AMOUNT : Montant du paiement en FCFA
    amount = Column(
        Float,
        nullable=False,
        comment="Montant du paiement en FCFA"
    )
    
    # Colonne PAYMENTMETHOD : Méthode de paiement utilisée
    payment_method = Column(
        SQLEnum(PaymentMethod, native_enum=False),
        nullable=False,
        index=True,  # Index pour filtrer par méthode
        comment="Méthode de paiement (mtn, orange)"
    )
    
    # Colonne PAYMENTTYPE : Type de paiement
    payment_type = Column(
        SQLEnum(PaymentType, native_enum=False),
        nullable=False,
        index=True,  # Index pour filtrer par type
        comment="Type de paiement (booking, caution, subscription)"
    )
    
    # Colonne PHONENUMBER : Numéro de téléphone utilisé
    # Format: +237XXXXXXXXX ou 237XXXXXXXXX
    phone_number = Column(
        String(20),
        nullable=False,
        comment="Numéro de téléphone pour le paiement MTN/Orange Money"
    )
    
    # Colonne STATUS : Énumération du statut du paiement
    status = Column(
        SQLEnum(PaymentStatus, native_enum=False),
        default=PaymentStatus.PENDING,
        nullable=False,
        index=True,  # Index pour filtrer par statut
        comment="Statut du paiement (pending/success/failed/cancelled/refunded)"
    )
    
    # Colonne TRANSACTIONID : ID du prestataire (MTN ou Orange)
    # Utilisé pour les requêtes de vérification et remboursement
    transaction_id = Column(
        String(100),
        nullable=True,
        unique=True,  # Chaque transaction doit être unique
        comment="Identifiant unique du prestataire (pour vérification)"
    )
    
    # Colonne CREATEDAT : Timestamp de création
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de création du paiement"
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
        """Convertit l'objet Payment en dictionnaire"""
        return {
            "id": str(self.id),
            "user_id": str(self.user_id),
            "booking_id": str(self.booking_id) if self.booking_id else None,
            "amount": self.amount,
            "payment_method": self.payment_method.value,
            "payment_type": self.payment_type.value,
            "phone_number": self.phone_number,
            "status": self.status.value,
            "transaction_id": self.transaction_id,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }

# Modèle SQLAlchemy pour l'historique des transactions
class PaymentTransaction(Base):
    """
    Modèle pour l'historique détaillé de chaque tentative de paiement.
    Utile pour l'audit et le dépannage des paiements échoués.
    
    Attributs:
        id: Identifiant unique
        payment_id: FK vers Payment.id
        status: Statut de cette tentative
        error_message: Message d'erreur si échouée
        provider_response: Réponse complète du prestataire
        created_at: Timestamp
    """
    
    # Nom de la table en base de données
    __tablename__ = "payment_transactions"
    
    # Colonne ID
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique de la tentative"
    )
    
    # Colonne PAYMENTID : Clé étrangère vers Payment
    payment_id = Column(
        UUID(as_uuid=True),
        ForeignKey("payments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="UUID du paiement parent"
    )
    
    # Colonne STATUS : Résultat de cette tentative
    status = Column(
        SQLEnum(PaymentStatus, native_enum=False),
        nullable=False,
        comment="Statut de cette tentative de paiement"
    )
    
    # Colonne ERRORMESSAGE : Détails de l'erreur si applicable
    error_message = Column(
        String(500),
        nullable=True,
        comment="Message d'erreur si la tentative a échoué"
    )
    
    # Colonne PROVIDERRESPONSE : Réponse complète du prestataire (JSON)
    provider_response = Column(
        String(2000),
        nullable=True,
        comment="Réponse complète du prestataire (pour débogage)"
    )
    
    # Timestamp de création
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de cette tentative"
    )
