# Import datetime pour gérer les timestamps
from datetime import datetime

# Import de uuid pour générer les identifiants uniques
import uuid

# Import de Enum pour les énumérations (statut du trajet, etc)
from enum import Enum

# Import de sqlalchemy pour créer les modèles ORM
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base

# Créer la classe de base pour tous les modèles SQLAlchemy
Base = declarative_base()

# Énumération pour les statuts possibles d'un trajet
class TripStatus(str, Enum):
    """
    Énumération des statuts pour un trajet:
    - ACTIVE: Trajet ouvert aux réservations
    - ONGOING: Trajet en cours (le chauffeur a commencé le voyage)
    - COMPLETED: Trajet terminé avec succès
    - CANCELLED: Trajet annulé par le chauffeur ou système
    """
    ACTIVE = "active"       # Ouvert aux réservations
    ONGOING = "ongoing"     # En cours
    COMPLETED = "completed" # Terminé
    CANCELLED = "cancelled" # Annulé

# Énumération pour les options de confort disponibles dans un trajet
class TripOption(str, Enum):
    """
    Options de confort/équipements disponibles dans le véhicule:
    - AC: Climatisation
    - SMOKING: Fumage autorisé
    - MUSIC: Musique à bord
    - LUGGAGE: Espace pour bagages
    - WIFI: Connexion WiFi à bord
    - WATER: Eau gratuite fournie
    """
    AC = "ac"               # Climatisation
    SMOKING = "smoking"     # Fumage autorisé
    MUSIC = "music"         # Musique
    LUGGAGE = "luggage"     # Bagages
    WIFI = "wifi"           # WiFi
    WATER = "water"         # Eau


# Modèle SQLAlchemy pour un trajet (table 'trips' en base de données)
class Trip(Base):
    """
    Modèle représentant un trajet publié par un chauffeur.
    
    Attributs:
        id: Identifiant unique UUID du trajet
        driver_id: UUID du chauffeur qui a créé le trajet
        departure_city: Ville de départ (ex: 'Douala', 'Yaoundé')
        arrival_city: Ville d'arrivée
        departure_time: Date et heure de départ prévue
        total_seats: Nombre total de places dans le véhicule
        available_seats: Nombre de places encore disponibles
        price_per_seat: Prix en FCFA par passager
        vehicle_model: Modèle du véhicule (ex: 'Suzuki Swift')
        vehicle_plate: Plaque d'immatriculation du véhicule
        status: Statut actuel du trajet (active, ongoing, completed, cancelled)
        is_prime: Indique si le chauffeur a le statut Prime (badge doré)
        created_at: Timestamp de création du trajet
        updated_at: Timestamp de dernière modification
    """
    
    # Nom de la table en base de données
    __tablename__ = "trips"
    
    # Colonne ID : identifiant unique de type UUID, clé primaire
    # server_default: postgres génère la valeur par défaut
    # primary_key=True: c'est l'identifiant unique de ce trajet
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique du trajet (UUID)"
    )
    
    # Colonne DRIVER_ID : UUID du chauffeur propriétaire du trajet
    # On ne crée pas de contrainte FK vers la table users du service auth (microservices séparentés)
    driver_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        index=True,  # Index pour accélérer les recherches par driver_id
        comment="UUID du chauffeur qui crée le trajet"
    )
    
    # Colonne DEPARTURE_CITY : Ville de départ (Douala, Yaoundé, Bafoussam, etc)
    departure_city = Column(
        String(100),
        nullable=False,
        index=True,  # Index pour recherches rapides par ville
        comment="Ville de départ du trajet"
    )
    
    # Colonne ARRIVAL_CITY : Ville d'arrivée
    arrival_city = Column(
        String(100),
        nullable=False,
        index=True,  # Index pour recherches rapides par ville
        comment="Ville d'arrivée du trajet"
    )
    
    # Colonne DEPARTURE_TIME : Date et heure exacte du départ
    # On crée un index pour les recherches par date/heure
    departure_time = Column(
        DateTime,
        nullable=False,
        index=True,  # Index pour filtrer par date
        comment="Date et heure de départ du trajet"
    )
    
    # Colonne TOTAL_SEATS : Capacité totale du véhicule (ex: 5 places)
    total_seats = Column(
        Integer,
        nullable=False,
        comment="Nombre total de places dans le véhicule"
    )
    
    # Colonne AVAILABLE_SEATS : Places restantes disponibles
    # Calculée dynamiquement en fonction des réservations
    available_seats = Column(
        Integer,
        nullable=False,
        comment="Nombre de places encore disponibles pour réservation"
    )
    
    # Colonne PRICE_PER_SEAT : Tarif en FCFA par place
    # Double pour supporter les tarifs décimaux (5000.50 par exemple)
    price_per_seat = Column(
        Float,
        nullable=False,
        comment="Prix en FCFA par place pour ce trajet"
    )
    
    # Colonne VEHICLE_MODEL : Marque et modèle du véhicule
    # Exemple: "Suzuki Swift 2020", "Toyota Fortuner"
    vehicle_model = Column(
        String(100),
        nullable=False,
        comment="Modèle et année du véhicule utilisé"
    )
    
    # Colonne VEHICLE_PLATE : Plaque d'immatriculation
    # Format Cameroun: CCXXXX (lettres + numéros)
    vehicle_plate = Column(
        String(20),
        nullable=False,
        comment="Plaque d'immatriculation du véhicule"
    )

    # Colonne VEHICLE_ID : UUID du véhicule enregistré (optionnel)
    vehicle_id = Column(
        UUID(as_uuid=True),
        nullable=True,
        comment="UUID du véhicule enregistré dans le user-service"
    )
    
    # Colonne STATUS : Énumération du statut du trajet
    # SqlEnum utilise la colonne comme VARCHAR et stocke la valeur string (active, ongoing, etc)
    status = Column(
        SQLEnum(TripStatus, native_enum=False),
        default=TripStatus.ACTIVE,
        nullable=False,
        index=True,  # Index pour filtrer par statut rapidement
        comment="Statut actuel du trajet (active/ongoing/completed/cancelled)"
    )
    
    # Colonne IS_PRIME : Booléen indiquant si le chauffeur a l'abonnement Prime
    # Un chauffeur Prime affiche un badge doré dans l'app
    is_prime = Column(
        Boolean,
        default=False,
        nullable=False,
        comment="Indique si le chauffeur avec statut Prime"
    )
    
    # Colonne CREATED_AT : Timestamp de création
    # Se remplit automatiquement avec la date/heure courante
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de création du trajet"
    )
    
    # Colonne UPDATED_AT : Timestamp de dernière modification
    # Se met à jour automatiquement à chaque modification
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,  # Mise à jour auto lors du UPDATE
        nullable=False,
        comment="Date et heure de dernière modification"
    )
    
    # Méthode pour convertir l'objet en dictionnaire
    def to_dict(self):
        """Convertit l'objet Trip en dictionnaire (utile pour les sérialisations)"""
        return {
            "id": str(self.id),
            "driver_id": str(self.driver_id),
            "departure_city": self.departure_city,
            "arrival_city": self.arrival_city,
            "departure_time": self.departure_time.isoformat(),
            "total_seats": self.total_seats,
            "available_seats": self.available_seats,
            "price_per_seat": self.price_per_seat,
            "vehicle_model": self.vehicle_model,
            "vehicle_plate": self.vehicle_plate,
            "vehicle_id": str(self.vehicle_id) if self.vehicle_id else None,
            "status": self.status.value,
            "is_prime": self.is_prime,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


# Modèle SQLAlchemy pour les waypoints (étapes intermédiaires d'un trajet)
class Waypoint(Base):
    """
    Modèle représentant une ville d'étape intermédiaire lors d'un trajet.
    
    Exemple: Trajet Douala → Yaoundé avec étape à Nkongsamba
    
    Attributs:
        id: Identifiant unique UUID du waypoint
        trip_id: UUID du trajet parent
        city_name: Nom de la ville d'étape
        order_index: Position dans la séquence (1, 2, 3, etc)
        estimated_time: Heure estimée d'arrivée à cette étape
    """
    
    # Nom de la table en base de données
    __tablename__ = "waypoints"
    
    # Colonne ID : identifiant unique de type UUID
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique du waypoint"
    )
    
    # Colonne TRIP_ID : Clé étrangère vers la table trips
    # Cascade delete: si le trajet est supprimé, les waypoints aussi
    trip_id = Column(
        UUID(as_uuid=True),
        ForeignKey("trips.id", ondelete="CASCADE"),
        nullable=False,
        index=True,  # Index pour recherches rapides par trip_id
        comment="UUID du trajet parent"
    )
    
    # Colonne CITY_NAME : Nom de la ville d'étape
    city_name = Column(
        String(100),
        nullable=False,
        comment="Nom de la ville à cette étape"
    )
    
    # Colonne ORDER_INDEX : Position ordonnée dans la séquence (1=première étape, 2=deuxième, etc)
    order_index = Column(
        Integer,
        nullable=False,
        comment="Position de cette étape dans le trajet (1, 2, 3...)"
    )
    
    # Colonne ESTIMATED_TIME : Heure estimée d'arrivée à cette étape
    # Permet d'afficher un itinéraire détaillé aux passagers
    estimated_time = Column(
        DateTime,
        nullable=False,
        comment="Heure estimée d'arrivée à cette étape du trajet"
    )
    
    # Timestamp de création
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure de création du waypoint"
    )


# Modèle SQLAlchemy pour les options de confort d'un trajet
class TripConfort(Base):
    """
    Modèle pour stocker les options de confort associées à un trajet.
    
    Example: Un trajet peut avoir les options: climatisation, WiFi, eau gratuite
    
    Attributs:
        id: Identifiant unique UUID
        trip_id: UUID du trajet parent
        option: Type d'option (ac, smoking, music, luggage, wifi, water)
    """
    
    # Nom de la table en base de données
    __tablename__ = "trip_comforts"
    
    # Colonne ID : identifiant unique
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
        comment="Identifiant unique de l'option confort"
    )
    
    # Colonne TRIP_ID : Clé étrangère vers trips
    # CASCADE: supprimer cette option si le trajet est supprimé
    trip_id = Column(
        UUID(as_uuid=True),
        ForeignKey("trips.id", ondelete="CASCADE"),
        nullable=False,
        index=True,  # Index pour chercher rapidement par trip
        comment="UUID du trajet parent"
    )
    
    # Colonne OPTION : Type d'option (valeur de l'énumération TripOption)
    option = Column(
        SQLEnum(TripOption, native_enum=False),
        nullable=False,
        comment="Type de confort/équipement (ac, smoking, music, luggage, wifi, water)"
    )
    
    # Timestamp de création
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
        comment="Date et heure d'ajout de cette option au trajet"
    )
