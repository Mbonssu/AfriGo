# Import SQLAlchemy pour les requêtes DB
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func

# Import datetime et timedelta pour manipuler les dates
from datetime import datetime, timedelta

# Import UUID pour manipuler les identifiants
from uuid import UUID

# Import de Logging pour tracer les opérations
import logging

# Import des modèles SQLAlchemy
from app.models.trip import Trip, Waypoint, TripConfort, TripStatus, TripOption

# Import des DTOs Pydantic
from app.schemas.trip import (
    TripCreate, TripUpdate, TripResponse, WaypointCreate,
    WaypointResponse, TripSearchRequest, TripSearchResponse
)

# Créer un logger pour ce service (pour debug et monitoring)
logger = logging.getLogger(__name__)


# Classe de service métier pour les trajets
class TripService:
    """
    Service métier pour gérer les trajets.
    Contient la logique métier pour créer, rechercher, modifier les trajets.
    """
    
    # ===================================================
    # MÉTHODES DE CRÉATION
    # ===================================================
    
    @staticmethod
    def create_trip(db: Session, driver_id: UUID, trip_data: TripCreate) -> TripResponse:
        """
        Crée un nouveau trajet et le sauvegarde en base de données.
        
        Args:
            db: Session SQLAlchemy pour accéder à la base
            driver_id: UUID du chauffeur qui crée le trajet
            trip_data: Données du trajet dans un DTO TripCreate
        
        Returns:
            TripResponse: Le trajet créé avec tous ses détails
        
        Raises:
            ValueError: Si les données sont invalides
        """
        
        try:
            # Logging pour tracer la création
            logger.info(f"Création nouveau trajet pour chauffeur {driver_id}")

            # Règles métier réalistes
            if trip_data.departure_city.strip().lower() == trip_data.arrival_city.strip().lower():
                raise ValueError("La ville de depart et d'arrivee doivent etre differentes")

            if trip_data.departure_time < datetime.utcnow() + timedelta(minutes=30):
                raise ValueError("Le depart doit etre prevu au moins 30 minutes a l'avance")

            departure_hour = trip_data.departure_time.hour
            if departure_hour < 5 or departure_hour >= 22:
                raise ValueError("L'heure de depart doit etre comprise entre 05:00 et 22:00")
            
            # Créer un objet Trip à partir du DTO TripCreate
            # Le nombre initial de places disponibles = places totales
            new_trip = Trip(
                driver_id=driver_id,  # Associer au chauffeur
                departure_city=trip_data.departure_city,  # Ville de départ
                arrival_city=trip_data.arrival_city,  # Ville d'arrivée
                departure_time=trip_data.departure_time,  # Heure de départ
                total_seats=trip_data.total_seats,  # Places totales
                available_seats=trip_data.total_seats,  # Initialement, toutes les places sont libres
                price_per_seat=trip_data.price_per_seat,  # Prix par place
                vehicle_model=trip_data.vehicle_model,  # Modèle du véhicule
                vehicle_plate=trip_data.vehicle_plate,  # Plaque du véhicule
                vehicle_id=UUID(trip_data.vehicle_id) if trip_data.vehicle_id else None,
                is_prime=trip_data.is_prime,  # Statut Prime du chauffeur
                status=TripStatus.ACTIVE  # Le trajet est ACTIVE dès sa création
            )
            
            # Ajouter le trajet à la session SQLAlchemy (pas encore sauvegardé)
            db.add(new_trip)
            
            # Sauvegarder le trajet et récupérer ses détails (y compris l'ID auto-généré)
            db.flush()  # Exécuter la requête INSERT pour générer l'ID
            
            # Créer les waypoints (étapes intermédiaires) si fournis
            waypoints = None
            if trip_data.waypoints:  # Si il y a des étapes à ajouter
                waypoints = []
                # Boucler sur chaque étape fournie
                for waypoint_data in trip_data.waypoints:
                    # Créer un objet Waypoint en base
                    waypoint = Waypoint(
                        trip_id=new_trip.id,  # Associer au trajet qu'on vient de créer
                        city_name=waypoint_data.city_name,  # Nom de la ville
                        order_index=waypoint_data.order_index,  # Position (1, 2, 3...)
                        estimated_time=waypoint_data.estimated_time  # Heure estimée
                    )
                    # Ajouter à la session
                    db.add(waypoint)
                    waypoints.append(waypoint)
                
                # Flush pour générer les IDs et created_at des waypoints
                db.flush()
                
                # Maintenant convertir en WaypointResponse avec tous les champs remplis
                waypoints = [WaypointResponse.from_orm(wp) for wp in waypoints]
            
            # Créer les options de confort (climatisation, WiFi, etc) si fournis
            comfort_options = None
            if trip_data.comfort_options:  # Si il y a des options à ajouter
                comfort_options = []
                # Boucler sur chaque option fournie
                for option in trip_data.comfort_options:
                    # Valider que l'option est valide (dans l'énumération TripOption)
                    if option not in [o.value for o in TripOption]:  # o.value = "ac", "smoking", etc
                        # Logger l'erreur
                        logger.warning(f"Option invalide: {option}")
                        # Ignorer cette option et continuer
                        continue
                    
                    # Créer un objet TripConfort en base
                    confort = TripConfort(
                        trip_id=new_trip.id,  # Associer au trajet
                        option=TripOption(option)  # Convertir la string en énumération
                    )
                    # Ajouter à la session
                    db.add(confort)
                    # Ajouter à la liste pour retour
                    comfort_options.append(option)
            
            # Valider et sauvegarder TOUT dans la base de données
            db.commit()
            
            # Logging du succès
            logger.info(f"Trajet créé avec succès: {new_trip.id}")
            
            # Retourner le trajet créé dans un DTO TripResponse
            return TripResponse(
                id=new_trip.id,
                driver_id=new_trip.driver_id,
                departure_city=new_trip.departure_city,
                arrival_city=new_trip.arrival_city,
                departure_time=new_trip.departure_time,
                total_seats=new_trip.total_seats,
                available_seats=new_trip.available_seats,
                price_per_seat=new_trip.price_per_seat,
                vehicle_model=new_trip.vehicle_model,
                vehicle_plate=new_trip.vehicle_plate,
                status=new_trip.status.value,  # Convertir l'énumération en string
                is_prime=new_trip.is_prime,
                created_at=new_trip.created_at,
                updated_at=new_trip.updated_at,
                waypoints=waypoints,  # Inclure les étapes si créées
                comfort_options=comfort_options  # Inclure les options confort si créées
            )
        
        except Exception as e:
            # En cas d'erreur, annuler les modifications
            db.rollback()
            # Logger l'erreur
            logger.error(f"Erreur lors de la création du trajet: {str(e)}")
            # Lever l'exception pour que le contrôleur la gère
            raise
    
    # ===================================================
    # MÉTHODES DE LECTURE (GET)
    # ===================================================
    
    @staticmethod
    def get_trip_by_id(db: Session, trip_id: UUID) -> TripResponse:
        """
        Récupère un trajet spécifique par son ID.
        
        Args:
            db: Session SQLAlchemy
            trip_id: UUID du trajet à récupérer
        
        Returns:
            TripResponse: Le trajet avec tous ses détails
        
        Raises:
            ValueError: Si le trajet n'existe pas
        """
        
        # Requête DB simple: SELECT * FROM trips WHERE id = trip_id LIMIT 1
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        
        # Vérifier que le trajet existe
        if not trip:
            # Logger l'erreur
            logger.warning(f"Trajet non trouvé: {trip_id}")
            # Lever une exception
            raise ValueError(f"Trajet avec ID {trip_id} non trouvé")
        
        # Récupérer les waypoints associés au trajet
        waypoints = db.query(Waypoint).filter(
            Waypoint.trip_id == trip_id
        ).order_by(Waypoint.order_index).all()  # Trier par position
        
        # Convertir les waypoints en DTOs
        waypoints_data = [
            WaypointResponse.from_orm(wp) for wp in waypoints
        ] if waypoints else None
        
        # Récupérer les options de confort associées au trajet
        comforts = db.query(TripConfort).filter(
            TripConfort.trip_id == trip_id
        ).all()
        
        # Convertir les options en list de strings
        comfort_options = [
            c.option.value for c in comforts  # c.option est une énumération, .value = "ac", "smoking"
        ] if comforts else None
        
        # Logger le succès
        logger.info(f"Trajet récupéré: {trip_id}")
        
        # Retourner le trajet dans un DTO TripResponse
        return TripResponse(
            id=trip.id,
            driver_id=trip.driver_id,
            departure_city=trip.departure_city,
            arrival_city=trip.arrival_city,
            departure_time=trip.departure_time,
            total_seats=trip.total_seats,
            available_seats=trip.available_seats,
            price_per_seat=trip.price_per_seat,
            vehicle_model=trip.vehicle_model,
            vehicle_plate=trip.vehicle_plate,
            status=trip.status.value,  # Convertir énumération en string
            is_prime=trip.is_prime,
            created_at=trip.created_at,
            updated_at=trip.updated_at,
            waypoints=waypoints_data,
            comfort_options=comfort_options
        )
    
    # ===================================================
    # MÉTHODES DE RECHERCHE (SEARCH)
    # ===================================================
    
    @staticmethod
    def search_trips(db: Session, search_request: TripSearchRequest) -> TripSearchResponse:
        """
        Recherche les trajets selon des critères spécifiques.
        
        Args:
            db: Session SQLAlchemy
            search_request: Critères de recherche (ville départ, arrivée, date, etc)
        
        Returns:
            TripSearchResponse: Résultats de la recherche avec filtres appliqués
        """
        
        logger.info(f"Recherche trajets: {search_request.from_city or '*'} → {search_request.to_city or '*'}")
        
        # Construire la requête de base: SELECT * FROM trips WHERE ...
        query = db.query(Trip)
        
        # Filtrer par ville de départ (case-insensitive avec LOWER) si fournie
        if search_request.from_city:
            query = query.filter(
                func.lower(Trip.departure_city) == func.lower(search_request.from_city)
            )
        
        # Filtrer par ville d'arrivée (case-insensitive) si fournie
        if search_request.to_city:
            query = query.filter(
                func.lower(Trip.arrival_city) == func.lower(search_request.to_city)
            )
        
        # Filtrer par date de départ si fournie
        if search_request.departure_date:
            # Parser la date au format "YYYY-MM-DD"
            search_date = datetime.strptime(search_request.departure_date, "%Y-%m-%d")
            # Créer une plage: minuit du jour + 24h (fin du jour)
            start_of_day = search_date.replace(hour=0, minute=0, second=0, microsecond=0)
            end_of_day = search_date.replace(hour=23, minute=59, second=59, microsecond=999999)
            # Filtrer les trajets de ce jour
            query = query.filter(
                and_(
                    Trip.departure_time >= start_of_day,
                    Trip.departure_time <= end_of_day
                )
            )
        else:
            # Si pas de date fournie, chercher uniquement les trajets futurs (date > maintenant)
            query = query.filter(Trip.departure_time >= datetime.utcnow())
        
        # Filtrer par nombre de places disponibles
        # Exemple: chercher 2 passagers → ne montrer que trajets avec >= 2 places
        query = query.filter(Trip.available_seats >= search_request.passenger_count)
        
        # Filtrer par statut: ne montrer que les trajets ACTIVE
        query = query.filter(Trip.status == TripStatus.ACTIVE)
        
        # Trier les résultats selon le critère spécifié
        if search_request.sort_by == "price":
            # Trier par prix croissant (moins cher d'abord)
            query = query.order_by(Trip.price_per_seat.asc())
        else:
            # Par défaut, trier par heure de départ
            query = query.order_by(Trip.departure_time.asc())
        
        # Exécuter la requête et récupérer les résultats
        trips = query.all()
        
        # Convertir chaque trajet en DTO TripResponse
        trips_response = []
        for trip in trips:
            # Pour chaque trajet, récupérer ses waypoints et options
            waypoints = db.query(Waypoint).filter(
                Waypoint.trip_id == trip.id
            ).order_by(Waypoint.order_index).all()
            
            waypoints_data = [
                WaypointResponse.from_orm(wp) for wp in waypoints
            ] if waypoints else None
            
            comforts = db.query(TripConfort).filter(
                TripConfort.trip_id == trip.id
            ).all()
            
            comfort_options = [
                c.option.value for c in comforts
            ] if comforts else None
            
            # Créer le DTO du trajet
            trip_response = TripResponse(
                id=trip.id,
                driver_id=trip.driver_id,
                departure_city=trip.departure_city,
                arrival_city=trip.arrival_city,
                departure_time=trip.departure_time,
                total_seats=trip.total_seats,
                available_seats=trip.available_seats,
                price_per_seat=trip.price_per_seat,
                vehicle_model=trip.vehicle_model,
                vehicle_plate=trip.vehicle_plate,
                status=trip.status.value,
                is_prime=trip.is_prime,
                created_at=trip.created_at,
                updated_at=trip.updated_at,
                waypoints=waypoints_data,
                comfort_options=comfort_options
            )
            trips_response.append(trip_response)
        
        # Logging du nombre de résultats
        logger.info(f"Recherche trouvée {len(trips_response)} trajets")
        
        # Créer l'objet réponse avec les filtres appliqués
        filters_applied = {
            "from_city": search_request.from_city,
            "to_city": search_request.to_city,
            "departure_date": search_request.departure_date or "any",
            "passenger_count": search_request.passenger_count,
            "sort_by": search_request.sort_by
        }
        
        # Retourner les résultats encapsulés dans TripSearchResponse
        return TripSearchResponse(
            total_results=len(trips_response),  # Nombre total de trajets trouvés
            trips=trips_response,  # Liste des trajets matchant les critères
            filters_applied=filters_applied  # Filtres qui ont été appliqués
        )
    
    # ===================================================
    # MÉTHODES DE MODIFICATION (UPDATE)
    # ===================================================
    
    @staticmethod
    def update_trip(db: Session, trip_id: UUID, trip_data: TripUpdate) -> TripResponse:
        """
        Modifie un trajet existant (seulement les champs fournis).
        
        Args:
            db: Session SQLAlchemy
            trip_id: UUID du trajet à modifier
            trip_data: Données à modifier (peut être partiel)
        
        Returns:
            TripResponse: Le trajet mis à jour
        
        Raises:
            ValueError: Si le trajet n'existe pas
        """
        
        logger.info(f"Modification trajet: {trip_id}")
        
        # Récupérer le trajet existant
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        
        # Vérifier qu'il existe
        if not trip:
            logger.warning(f"Trajet non trouvé: {trip_id}")
            raise ValueError(f"Trajet avec ID {trip_id} non trouvé")
        
        # Mettre à jour seulement les champs qui sont fournis (not None)
        if trip_data.departure_city is not None:
            trip.departure_city = trip_data.departure_city
        
        if trip_data.arrival_city is not None:
            trip.arrival_city = trip_data.arrival_city
        
        if trip_data.departure_time is not None:
            trip.departure_time = trip_data.departure_time
        
        if trip_data.price_per_seat is not None:
            trip.price_per_seat = trip_data.price_per_seat
        
        if trip_data.vehicle_model is not None:
            trip.vehicle_model = trip_data.vehicle_model
        
        if trip_data.status is not None:
            # Valider que le statut fourni est une valeur enum valide
            try:
                trip.status = TripStatus(trip_data.status)
            except ValueError:
                logger.warning(f"Statut invalide: {trip_data.status}")
                raise ValueError(f"Statut invalide: {trip_data.status}")
        
        # Sauvegarder les modifications
        db.commit()
        
        logger.info(f"Trajet modifié avec succès: {trip_id}")
        
        # Récupérer et retourner le trajet modifié (via la fonction get_trip_by_id)
        return TripService.get_trip_by_id(db, trip_id)
    
    # ===================================================
    # MÉTHODES DE SUPPRESSION (DELETE)
    # ===================================================
    
    @staticmethod
    def delete_trip(db: Session, trip_id: UUID) -> bool:
        """
        Supprime un trajet (logiquement en le marquant comme CANCELLED).
        Ne supprime pas réellement les données pour conserver l'historique.
        
        Args:
            db: Session SQLAlchemy
            trip_id: UUID du trajet à supprimer
        
        Returns:
            bool: True si suppression réussie, False sinon
        """
        
        logger.info(f"Suppression trajet: {trip_id}")
        
        # Récupérer le trajet
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        
        # Vérifier qu'il existe
        if not trip:
            logger.warning(f"Trajet non trouvé: {trip_id}")
            raise ValueError(f"Trajet avec ID {trip_id} non trouvé")
        
        # Marquer le trajet comme CANCELLED (soft delete)
        trip.status = TripStatus.CANCELLED
        
        # Sauvegarder la modification
        db.commit()
        
        logger.info(f"Trajet marqué comme annulé: {trip_id}")
        
        # Retourner True pour confirmer le succès
        return True
    
    # ===================================================
    # MÉTHODES UTILITAIRES
    # ===================================================
    
    @staticmethod
    def book_seat(db: Session, trip_id: UUID, passenger_count: int = 1) -> bool:
        """
        Réserve une ou plusieurs places dans un trajet.
        Décrémente le nombre de places disponibles.
        
        Args:
            db: Session SQLAlchemy
            trip_id: UUID du trajet
            passenger_count: Nombre de places à réserver (défaut 1)
        
        Returns:
            bool: True si réservation réussie, False si pas assez de places
        """
        
        logger.info(f"Réservation {passenger_count} place(s) trajet {trip_id}")
        
        # Récupérer le trajet
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        
        # Vérifier qu'il existe
        if not trip:
            logger.warning(f"Trajet non trouvé: {trip_id}")
            raise ValueError(f"Trajet avec ID {trip_id} non trouvé")
        
        # Vérifier qu'il y a assez de places disponibles
        if trip.available_seats < passenger_count:
            logger.warning(f"Pas assez de places: demandé {passenger_count}, disponible {trip.available_seats}")
            return False
        
        # Décrémenter les places disponibles
        trip.available_seats -= passenger_count
        
        # Sauvegarder
        db.commit()
        
        logger.info(f"Réservation réussie, places restantes: {trip.available_seats}")
        
        return True

    @staticmethod
    def get_trips_by_driver(db: Session, driver_id: UUID) -> list:
        """Récupère tous les trajets d'un chauffeur."""
        logger.info(f"Récupération trajets du chauffeur {driver_id}")

        trips = db.query(Trip).filter(
            Trip.driver_id == driver_id
        ).order_by(Trip.departure_time.desc()).all()

        results = []
        for trip in trips:
            waypoints = db.query(Waypoint).filter(
                Waypoint.trip_id == trip.id
            ).order_by(Waypoint.order_index).all()
            waypoints_data = [WaypointResponse.from_orm(wp) for wp in waypoints] if waypoints else None

            comforts = db.query(TripConfort).filter(
                TripConfort.trip_id == trip.id
            ).all()
            comfort_options = [c.option.value for c in comforts] if comforts else None

            results.append(TripResponse(
                id=trip.id,
                driver_id=trip.driver_id,
                departure_city=trip.departure_city,
                arrival_city=trip.arrival_city,
                departure_time=trip.departure_time,
                total_seats=trip.total_seats,
                available_seats=trip.available_seats,
                price_per_seat=trip.price_per_seat,
                vehicle_model=trip.vehicle_model,
                vehicle_plate=trip.vehicle_plate,
                status=trip.status.value,
                is_prime=trip.is_prime,
                created_at=trip.created_at,
                updated_at=trip.updated_at,
                waypoints=waypoints_data,
                comfort_options=comfort_options,
            ))

        logger.info(f"{len(results)} trajets trouvés pour chauffeur {driver_id}")
        return results
