# Import BaseModel from Pydantic pour créer les DTOs (Data Transfer Objects)
from pydantic import BaseModel, Field

# Import datetime pour typer les champs date/heure
from datetime import datetime

# Import List pour typer les listes
from typing import List, Optional

# Import UUID pour les identifiants
from uuid import UUID

# =====================================================
# SCHÉMAS POUR LES WAYPOINTS (Étapes intermédiaires)
# =====================================================

# DTO pour créer un waypoint - données envoyées par le client
class WaypointCreate(BaseModel):
    """
    Schéma pour créer une étape intermédiaire.
    Envoyé par le chauffeur lors de la création d'un trajet.
    """
    # Nom de la ville d'étape
    city_name: str = Field(
        ...,  # ... = champ obligatoire
        min_length=2,  # Au minimum 2 caractères
        max_length=100,  # Maximum 100 caractères
        description="Nom de la ville d'étape intermédiaire"
    )
    
    # Position ordonnée (1ère étape, 2ème étape, etc)
    order_index: int = Field(
        ...,
        ge=1,  # ge = greater or equal (>= 1)
        description="Position de cette étape dans l'ordre du trajet (1, 2, 3...)"
    )
    
    # Heure estimée d'arrivée à cette étape
    estimated_time: datetime = Field(
        ...,
        description="Heure estimée d'arrivée à cette étape du trajet"
    )


# DTO pour retourner les waypoints - réponse API
class WaypointResponse(BaseModel):
    """
    Schéma représentant une étape intermédiaire en réponse API.
    """
    # UUID de l'étape
    id: UUID = Field(..., description="Identifiant unique de l'étape")
    
    # UUID du trajet parent
    trip_id: UUID = Field(..., description="UUID du trajet parent")
    
    # Nom de la ville
    city_name: str = Field(..., description="Nom de la ville")
    
    # Position ordonnée
    order_index: int = Field(..., description="Position dans le trajet")
    
    # Heure estimée
    estimated_time: datetime = Field(..., description="Heure estimée")
    
    # Timestamp de création
    created_at: datetime = Field(..., description="Date de création")
    
    # Configuration Pydantic pour lire les données depuis les objets ORM SQLAlchemy
    class Config:
        # Autoriser la population du modèle à partir d'objets ORM
        from_attributes = True


# =====================================================
# SCHÉMAS POUR LES OPTIONS DE CONFORT
# =====================================================

# DTO pour retourner les options de confort
class TripConfortResponse(BaseModel):
    """
    Schéma pour les options de confort disponibles dans un trajet.
    """
    # Type d'option (ac, smoking, music, luggage, wifi, water)
    option: str = Field(
        ...,
        description="Type d'option: ac, smoking, music, luggage, wifi, water"
    )


# =====================================================
# SCHÉMAS POUR LES TRAJETS COMPLETS
# =====================================================

# DTO pour créer un trajet - données POST envoyées par le chauffeur
class TripCreate(BaseModel):
    """
    Schéma pour créer un nouveau trajet.
    Envoyé par le chauffeur quand il publie un trajet.
    """
    # UUID du chauffeur qui crée le trajet
    driver_id: str = Field(
        ...,
        description="UUID du chauffeur qui publie le trajet"
    )

    # Ville de départ obligatoire
    departure_city: str = Field(
        ...,
        min_length=2,
        max_length=100,
        description="Ville de départ (ex: 'Douala')"
    )
    
    # Ville d'arrivée obligatoire
    arrival_city: str = Field(
        ...,
        min_length=2,
        max_length=100,
        description="Ville d'arrivée (ex: 'Yaoundé')"
    )
    
    # Date et heure de départ obligatoire
    departure_time: datetime = Field(
        ...,
        description="Date et heure de départ du trajet"
    )
    
    # Nombre total de places dans le véhicule (de 2 à 8 places)
    total_seats: int = Field(
        ...,
        ge=2,  # Au minimum 2 places
        le=8,  # Au maximum 8 places
        description="Nombre total de places dans le véhicule (2-8)"
    )
    
    # Tarif en FCFA par place (exemple: 5000.00)
    price_per_seat: float = Field(
        ...,
        gt=0,  # gt = greater than (> 0)
        description="Prix en FCFA par place pour ce trajet"
    )
    
    # Modèle du véhicule (marque + modèle)
    vehicle_model: str = Field(
        ...,
        min_length=2,
        max_length=100,
        description="Modèle du véhicule (ex: 'Toyota Fortuner 2020')"
    )
    
    # Plaque d'immatriculation du véhicule
    vehicle_plate: str = Field(
        ...,
        min_length=5,
        max_length=20,
        description="Plaque d'immatriculation (ex: 'CC1234')"
    )
    
    # Indique si le chauffeur a le statut Prime
    is_prime: bool = Field(
        default=False,
        description="Indique si le chauffeur a l'abonnement Prime"
    )
    
    # UUID du véhicule enregistré (optionnel)
    vehicle_id: Optional[str] = Field(
        default=None,
        description="UUID du véhicule enregistré dans le user-service (optionnel)"
    )

    # Liste optionnelle des étapes intermédiaires
    waypoints: Optional[List[WaypointCreate]] = Field(
        default=None,
        description="Étapes intermédiaires du trajet (optionnel)"
    )
    
    # Liste optionnelle des options de confort
    comfort_options: Optional[List[str]] = Field(
        default=None,
        description="Options de confort disponibles (ac, smoking, music, luggage, wifi, water)"
    )


# DTO pour modifier un trajet - données PATCH/PUT
class TripUpdate(BaseModel):
    """
    Schéma pour modifier un trajet existant.
    Tous les champs sont optionnels (PATCH).
    """
    # Ville de départ (optionnel)
    departure_city: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=100,
        description="Nouvelle ville de départ (optionnel)"
    )
    
    # Ville d'arrivée (optionnel)
    arrival_city: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=100,
        description="Nouvelle ville d'arrivée (optionnel)"
    )
    
    # Date/heure de départ (optionnel)
    departure_time: Optional[datetime] = Field(
        default=None,
        description="Nouvelle date/heure de départ (optionnel)"
    )
    
    # Tarif par place (optionnel)
    price_per_seat: Optional[float] = Field(
        default=None,
        gt=0,
        description="Nouveau prix par place (optionnel)"
    )
    
    # Modèle du véhicule (optionnel)
    vehicle_model: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=100,
        description="Nouveau modèle de véhicule (optionnel)"
    )
    
    # Statut du trajet (optionnel) - pour annuler par exemple
    status: Optional[str] = Field(
        default=None,
        description="Nouveau statut: active, ongoing, completed, cancelled (optionnel)"
    )


# DTO pour retourner un trajet complet - réponse API
class TripResponse(BaseModel):
    """
    Schéma représentant un trajet complet en réponse API.
    Utilisé dans GET /trips/{id}, POST /trips, etc.
    """
    # UUID du trajet
    id: UUID = Field(..., description="Identifiant unique du trajet")
    
    # UUID du chauffeur
    driver_id: UUID = Field(..., description="UUID du chauffeur")
    
    # Ville de départ
    departure_city: str = Field(..., description="Ville de départ")
    
    # Ville d'arrivée
    arrival_city: str = Field(..., description="Ville d'arrivée")
    
    # Date/heure de départ
    departure_time: datetime = Field(..., description="Date/heure de départ")
    
    # Places totales
    total_seats: int = Field(..., description="Nombre total de places")
    
    # Places disponibles
    available_seats: int = Field(..., description="Nombre de places disponibles")
    
    # Prix par place
    price_per_seat: float = Field(..., description="Prix en FCFA par place")
    
    # Modèle du véhicule
    vehicle_model: str = Field(..., description="Modèle du véhicule")
    
    # Plaque d'immatriculation
    vehicle_plate: str = Field(..., description="Plaque d'immatriculation")
    
    # UUID du véhicule enregistré (optionnel)
    vehicle_id: Optional[str] = Field(
        default=None,
        description="UUID du véhicule enregistré dans le user-service"
    )

    # Statut actuel
    status: str = Field(..., description="Statut: active, ongoing, completed, cancelled")
    
    # Indique si Prime
    is_prime: bool = Field(..., description="Si le chauffeur a le statut Prime")
    
    # Timestamp de création
    created_at: datetime = Field(..., description="Date de création du trajet")
    
    # Timestamp de dernière modification
    updated_at: datetime = Field(..., description="Date de dernière modification")
    
    # Liste des étapes intermédiaires (optionnel)
    waypoints: Optional[List[WaypointResponse]] = Field(
        default=None,
        description="Étapes intermédiaires du trajet"
    )
    
    # Liste des options de confort (optionnel)
    comfort_options: Optional[List[str]] = Field(
        default=None,
        description="Options de confort disponibles"
    )
    
    # Configuration pour lire depuis les objets ORM
    class Config:
        from_attributes = True


# =====================================================
# SCHÉMAS POUR LA RECHERCHE DE TRAJETS
# =====================================================

# DTO pour les query parameters de la recherche
class TripSearchRequest(BaseModel):
    """
    Schéma pour les paramètres de recherche de trajets.
    Utilisé pour filtrer les trajets lors d'une recherche.
    """
    # Ville de départ (optionnelle — si omise, toutes les villes)
    from_city: Optional[str] = Field(
        default=None,
        description="Ville de départ pour la recherche (optionnel)"
    )
    
    # Ville d'arrivée (optionnelle — si omise, toutes les villes)
    to_city: Optional[str] = Field(
        default=None,
        description="Ville d'arrivée pour la recherche (optionnel)"
    )
    
    # Date de départ (optionnel) - si non fourni, tous les trajets futures
    # Format: ISO 8601 (ex: 2026-04-05)
    departure_date: Optional[str] = Field(
        default=None,
        description="Date de départ au format YYYY-MM-DD (optionnel)"
    )
    
    # Nombre de passagers recherchés (optionnel, par défaut 1)
    passenger_count: Optional[int] = Field(
        default=1,
        ge=1,  # Au minimum 1 passager
        le=8,  # Au maximum 8 passagers
        description="Nombre de places recherchées (1-8, optionnel)"
    )
    
    # Trieur les résultats par prix (optionnel)
    sort_by: Optional[str] = Field(
        default="departure_time",
        description="Trier par: 'departure_time', 'price' (optionnel)"
    )


# DTO pour retourner les résultats de recherche
class TripSearchResponse(BaseModel):
    """
    Schéma pour les résultats de recherche de trajets.
    """
    # Total de trajets trouvés
    total_results: int = Field(..., description="Nombre total de trajets trouvés")
    
    # Liste des trajets trouvés
    trips: List[TripResponse] = Field(..., description="Liste des trajets correspondant aux critères")
    
    # Filtre appliqué (pour affichage à l'utilisateur)
    filters_applied: dict = Field(..., description="Filtres appliqués lors de la recherche")


# =====================================================
# SCHÉMAS POUR LA GESTION DES ERREURS
# =====================================================

# DTO pour les erreurs API
class ErrorResponse(BaseModel):
    """
    Schéma standard pour les réponses d'erreur API.
    """
    # Code d'erreur HTTP (400, 404, 500, etc)
    code: int = Field(..., description="Code HTTP de l'erreur")
    
    # Message d'erreur lisible
    message: str = Field(..., description="Message d'erreur descriptif")
    
    # Détails additionnels (optionnel)
    details: Optional[dict] = Field(
        default=None,
        description="Détails additionnels sur l'erreur (optionnel)"
    )
