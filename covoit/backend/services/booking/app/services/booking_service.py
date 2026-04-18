# Import de SqlAlchemy pour les requêtes à la base de données
from sqlalchemy.orm import Session
from datetime import datetime
from uuid import UUID
from typing import Optional, List, Tuple

# Import des modèles SQLAlchemy
from app.models.booking import Booking, BookingNote, BookingStatus

# Import des schémas Pydantic
from app.schemas.booking import (
    BookingCreateRequest,
    BookingUpdateRequest,
    BookingResponse,
    BookingSearchRequest,
    BookingSearchResponse,
    BookingNoteCreateRequest,
    BookingNoteResponse,
    BoardingVerifyRequest,
    BoardingResponse,
)

class BookingService:
    """
    Service métier pour gérer toutes les réservations.
    Contient la logique pour créer, rechercher, modifier les réservations.
    """
    
    @staticmethod
    def create_booking(db: Session, request: BookingCreateRequest) -> BookingResponse:
        """
        Crée une nouvelle réservation en base de données.
        
        Paramètres:
            db: Session SQLAlchemy pour les requêtes
            request: Données de la réservation à créer (BookingCreateRequest)
        
        Retour:
            BookingResponse: La réservation créée avec son UUID
        
        Exemple d'utilisation:
            >>> booking_req = BookingCreateRequest(
            ...     trip_id=UUID('550e8400-e29b-41d4-a716-446655440000'),
            ...     passenger_id=UUID('550e8400-e29b-41d4-a716-446655440001'),
            ...     number_of_seats=2,
            ...     total_price=5000.0
            ... )
            >>> booking = BookingService.create_booking(db, booking_req)
        """
        
        # Créer l'objet Booking SQLAlchemy
        db_booking = Booking(
            trip_id=request.trip_id,                          # UUID du trajet
            passenger_id=request.passenger_id,                # UUID du passager
            number_of_seats=request.number_of_seats,          # Nombre de places
            total_price=request.total_price,                  # Prix total
            pickup_location=request.pickup_location,          # Lieu de rassemblement
            dropoff_location=request.dropoff_location,        # Lieu de dépôt
            status=BookingStatus.PENDING,                     # Démarre en PENDING
        )
        
        # Ajouter à la session et commiter
        db.add(db_booking)
        db.commit()
        
        # Actualiser depuis la base de données
        db.refresh(db_booking)
        
        # Retourner sous forme de schéma Pydantic
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def get_booking_by_id(db: Session, booking_id: UUID) -> Optional[BookingResponse]:
        """
        Récupère une réservation par son UUID.
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation à récupérer
        
        Retour:
            BookingResponse ou None si non trouvée
        
        Exemple:
            >>> booking = BookingService.get_booking_by_id(db, UUID('550e8400-e29b-41d4-a716-446655440000'))
            >>> if booking:
            ...     print(f"Trajet: {booking.trip_id}")
        """
        
        # Requête: SELECT * FROM bookings WHERE id = booking_id LIMIT 1
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        # Retourner None si pas trouvée, sinon convertir en schéma
        if db_booking is None:
            return None
        
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def get_passenger_bookings(
        db: Session,
        passenger_id: UUID,
        limit: int = 20,
        offset: int = 0
    ) -> BookingSearchResponse:
        """
        Récupère toutes les réservations d'un passager avec pagination.
        
        Paramètres:
            db: Session SQLAlchemy
            passenger_id: UUID du passager
            limit: Nombre maximum de résultats (défaut 20)
            offset: Décalage pour pagination (défaut 0)
        
        Retour:
            BookingSearchResponse: Liste paginée des réservations
        
        Exemple:
            >>> result = BookingService.get_passenger_bookings(
            ...     db,
            ...     UUID('550e8400-e29b-41d4-a716-446655440001'),
            ...     limit=10
            ... )
        """
        
        # Compter le total des réservations du passager
        total = db.query(Booking).filter(Booking.passenger_id == passenger_id).count()
        
        # Récupérer une page de réservations
        bookings = db.query(Booking).filter(
            Booking.passenger_id == passenger_id
        ).order_by(
            Booking.created_at.desc()  # Les plus récentes d'abord
        ).limit(limit).offset(offset).all()
        
        # Convertir chaque objet Booking en BookingResponse
        booking_list = [BookingResponse.model_validate(b) for b in bookings]
        
        # Retourner la réponse avec métadonnées de pagination
        return BookingSearchResponse(
            data=booking_list,
            total=total,
            count=len(booking_list),
            offset=offset,
            limit=limit,
        )
    
    @staticmethod
    def get_trip_bookings(
        db: Session,
        trip_id: UUID,
        limit: int = 50,
        offset: int = 0
    ) -> BookingSearchResponse:
        """
        Récupère toutes les réservations pour un trajet donné.
        Utile pour le conducteur pour voir who's en coche réservé.
        
        Paramètres:
            db: Session SQLAlchemy
            trip_id: UUID du trajet
            limit: Nombre maximum de résultats
            offset: Décalage pour pagination
        
        Retour:
            BookingSearchResponse: Liste des réservations pour ce trajet
        """
        
        # Compter le total des réservations pour ce trajet
        total = db.query(Booking).filter(Booking.trip_id == trip_id).count()
        
        # Récupérer les réservations
        bookings = db.query(Booking).filter(
            Booking.trip_id == trip_id
        ).order_by(
            Booking.created_at.desc()
        ).limit(limit).offset(offset).all()
        
        # Convertir les résultats
        booking_list = [BookingResponse.model_validate(b) for b in bookings]
        
        # Retourner la réponse
        return BookingSearchResponse(
            data=booking_list,
            total=total,
            count=len(booking_list),
            offset=offset,
            limit=limit,
        )
    
    @staticmethod
    def search_bookings(
        db: Session,
        request: BookingSearchRequest
    ) -> BookingSearchResponse:
        """
        Recherche les réservations avec filtres multiples.
        
        Filtres supportés:
        - trip_id: Trajet spécifique
        - passenger_id: Passager spécifique
        - status: Statut (pending, confirmed, cancelled, etc.)
        - min_price / max_price: Plage de prix
        
        Paramètres:
            db: Session SQLAlchemy
            request: Critères de recherche (BookingSearchRequest)
        
        Retour:
            BookingSearchResponse: Résultats filtrés et paginés
        """
        
        # Construire la requête de base
        query = db.query(Booking)
        
        # Appliquer les filtres progressivement
        
        # Filtrer par trajet si fourni
        if request.trip_id:
            query = query.filter(Booking.trip_id == request.trip_id)
        
        # Filtrer par passager si fourni
        if request.passenger_id:
            query = query.filter(Booking.passenger_id == request.passenger_id)
        
        # Filtrer par statut si fourni
        if request.status:
            query = query.filter(Booking.status == BookingStatus(request.status.value))
        
        # Filtrer par prix minimum si fourni
        if request.min_price is not None:
            query = query.filter(Booking.total_price >= request.min_price)
        
        # Filtrer par prix maximum si fourni
        if request.max_price is not None:
            query = query.filter(Booking.total_price <= request.max_price)
        
        # Compter le total AVANT d'appliquer limit/offset
        total = query.count()
        
        # Appliquer le tri
        query = query.order_by(Booking.created_at.desc())
        
        # Appliquer la pagination
        bookings = query.limit(request.limit).offset(request.offset).all()
        
        # Convertir les résultats
        booking_list = [BookingResponse.model_validate(b) for b in bookings]
        
        # Retourner la réponse paginée
        return BookingSearchResponse(
            data=booking_list,
            total=total,
            count=len(booking_list),
            offset=request.offset,
            limit=request.limit,
        )
    
    @staticmethod
    def update_booking(
        db: Session,
        booking_id: UUID,
        request: BookingUpdateRequest
    ) -> BookingResponse:
        """
        Met à jour une réservation (statut et notes).
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation à mettre à jour
            request: Données à mettre à jour (BookingUpdateRequest)
        
        Retour:
            BookingResponse: La réservation mise à jour
        
        Lève une exception:
            ValueError: Si la réservation n'existe pas
        """
        
        # Récupérer la réservation
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        # Vérifier que la réservation existe
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        # Mettre à jour le statut si fourni
        if request.status:
            db_booking.status = BookingStatus(request.status.value)
        
        # Mettre à jour les notes si fournies
        if request.driver_notes is not None:
            db_booking.driver_notes = request.driver_notes
        
        # Mettre à jour le timestamp
        db_booking.updated_at = datetime.utcnow()
        
        # Sauvegarder les changements
        db.commit()
        db.refresh(db_booking)
        
        # Retourner la réservation mise à jour
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def confirm_booking(
        db: Session,
        booking_id: UUID,
        payment_id: UUID
    ) -> BookingResponse:
        """
        Confirme une réservation après paiement réussi.
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation
            payment_id: UUID du paiement effectué
        
        Retour:
            BookingResponse: La réservation confirmée
        """
        
        # Récupérer la réservation
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        # Mettre à jour le statut et le paiement
        db_booking.status = BookingStatus.CONFIRMED
        db_booking.payment_id = payment_id
        db_booking.boarding_code = Booking.generate_boarding_code()
        db_booking.updated_at = datetime.utcnow()
        
        # Sauvegarder
        db.commit()
        db.refresh(db_booking)
        
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def cancel_booking(db: Session, booking_id: UUID) -> BookingResponse:
        """
        Annule une réservation.
        """
        
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        if db_booking.status == BookingStatus.COMPLETED:
            raise ValueError("Impossible d'annuler un trajet déjà complété")
        
        db_booking.status = BookingStatus.CANCELLED
        db_booking.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(db_booking)
        
        return BookingResponse.model_validate(db_booking)

    @staticmethod
    def accept_booking(db: Session, booking_id: UUID) -> BookingResponse:
        """
        Le conducteur accepte une réservation en attente.
        Transition : pending → accepted
        """
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()

        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")

        if db_booking.status != BookingStatus.PENDING:
            raise ValueError(
                f"Seules les réservations en attente peuvent être acceptées. "
                f"Statut actuel: {db_booking.status.value}"
            )

        db_booking.status = BookingStatus.ACCEPTED
        db_booking.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(db_booking)

        return BookingResponse.model_validate(db_booking)

    @staticmethod
    def reject_booking(db: Session, booking_id: UUID, reason: str = None) -> BookingResponse:
        """
        Le conducteur refuse une réservation en attente.
        Transition : pending → rejected
        """
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()

        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")

        if db_booking.status != BookingStatus.PENDING:
            raise ValueError(
                f"Seules les réservations en attente peuvent être refusées. "
                f"Statut actuel: {db_booking.status.value}"
            )

        db_booking.status = BookingStatus.REJECTED
        if reason:
            db_booking.driver_notes = reason
        db_booking.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(db_booking)

        return BookingResponse.model_validate(db_booking)

    @staticmethod
    def mark_no_show(db: Session, booking_id: UUID) -> BookingResponse:
        """
        Marque une réservation comme "passager absent" (no-show).
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation
        
        Retour:
            BookingResponse: La réservation marquée no-show
        """
        
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        # Mettre à jour le statut
        db_booking.status = BookingStatus.NO_SHOW
        db_booking.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(db_booking)
        
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def complete_booking(db: Session, booking_id: UUID) -> BookingResponse:
        """
        Marque une réservation comme complétée (trajet terminé).
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation
        
        Retour:
            BookingResponse: La réservation complétée
        """
        
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        # Seules les réservations confirmées peuvent être complétées
        if db_booking.status != BookingStatus.CONFIRMED:
            raise ValueError(
                f"Seules les réservations confirmées peuvent être complétées. "
                f"Statut actuel: {db_booking.status.value}"
            )
        
        # Mettre à jour le statut
        db_booking.status = BookingStatus.COMPLETED
        db_booking.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(db_booking)
        
        return BookingResponse.model_validate(db_booking)
    
    @staticmethod
    def add_booking_note(
        db: Session,
        booking_id: UUID,
        request: BookingNoteCreateRequest
    ) -> BookingNoteResponse:
        """
        Ajoute une note/commentaire à une réservation.
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation
            request: Contenu de la note (BookingNoteCreateRequest)
        
        Retour:
            BookingNoteResponse: La note créée
        """
        
        # Vérifier que la réservation existe
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")
        
        # Créer la note
        db_note = BookingNote(
            booking_id=booking_id,
            author_id=request.author_id,
            text=request.text,
        )
        
        # Sauvegarder
        db.add(db_note)
        db.commit()
        db.refresh(db_note)
        
        return BookingNoteResponse.model_validate(db_note)
    
    @staticmethod
    def get_booking_notes(
        db: Session,
        booking_id: UUID
    ) -> List[BookingNoteResponse]:
        """
        Récupère toutes les notes d'une réservation.
        
        Paramètres:
            db: Session SQLAlchemy
            booking_id: UUID de la réservation
        
        Retour:
            List[BookingNoteResponse]: Liste des notes
        """
        
        # Récupérer les notes triées par date de création
        notes = db.query(BookingNote).filter(
            BookingNote.booking_id == booking_id
        ).order_by(BookingNote.created_at.asc()).all()
        
        # Convertir en schémas
        return [BookingNoteResponse.model_validate(n) for n in notes]
    
    @staticmethod
    def get_booking_statistics(db: Session, passenger_id: Optional[UUID] = None) -> dict:
        """
        Calcule des statistiques sur les réservations.
        
        Paramètres:
            db: Session SQLAlchemy
            passenger_id: UUID du passager (optionnel)
        
        Retour:
            dict: Dictionnaire avec statistiques
        """
        
        # Construire la requête
        query = db.query(Booking)
        
        # Appliquer le filtre si fourni
        if passenger_id:
            query = query.filter(Booking.passenger_id == passenger_id)
        
        # Obtenir toutes les réservations
        bookings = query.all()
        
        if not bookings:
            # Retourner des zéros si pas de réservations
            return {
                "total_bookings": 0,
                "confirmed_count": 0,
                "completed_count": 0,
                "cancelled_count": 0,
                "pending_count": 0,
                "no_show_count": 0,
                "total_spent": 0.0,
                "average_trip_price": 0.0,
            }
        
        # Calculer les statistiques
        total = len(bookings)
        confirmed = sum(1 for b in bookings if b.status == BookingStatus.CONFIRMED)
        completed = sum(1 for b in bookings if b.status == BookingStatus.COMPLETED)
        cancelled = sum(1 for b in bookings if b.status == BookingStatus.CANCELLED)
        pending = sum(1 for b in bookings if b.status == BookingStatus.PENDING)
        no_show = sum(1 for b in bookings if b.status == BookingStatus.NO_SHOW)
        total_spent = sum(b.total_price for b in bookings if b.status in [BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
        average_price = total_spent / total if total > 0 else 0
        
        return {
            "total_bookings": total,
            "confirmed_count": confirmed,
            "completed_count": completed,
            "cancelled_count": cancelled,
            "pending_count": pending,
            "no_show_count": no_show,
            "total_spent": round(total_spent, 2),
            "average_trip_price": round(average_price, 2),
        }

    # ════════════════════════════════════════════════════════════════════════
    # BOARDING / VÉRIFICATION D'EMBARQUEMENT
    # ════════════════════════════════════════════════════════════════════════

    @staticmethod
    def get_boarding_code(db: Session, booking_id: UUID) -> dict:
        """
        Récupère le code d'embarquement d'une réservation.
        Appelé par le passager pour voir son code PIN / générer son QR.
        """
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")

        if db_booking.status != BookingStatus.CONFIRMED:
            raise ValueError("Le code d'embarquement n'est disponible que pour les réservations confirmées")

        # Si pas de code (ancienne réservation), en générer un maintenant
        if not db_booking.boarding_code:
            db_booking.boarding_code = Booking.generate_boarding_code()
            db.commit()
            db.refresh(db_booking)

        return {
            "booking_id": str(db_booking.id),
            "passenger_id": str(db_booking.passenger_id),
            "trip_id": str(db_booking.trip_id),
            "boarding_code": db_booking.boarding_code,
            "is_boarded": db_booking.is_boarded,
        }

    @staticmethod
    def verify_boarding(
        db: Session,
        booking_id: UUID,
        request: BoardingVerifyRequest,
    ) -> BoardingResponse:
        """
        Vérifie l'embarquement d'un passager.
        Le chauffeur saisit le code PIN donné par le passager,
        ou le code extrait du QR scanné.
        """
        db_booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if db_booking is None:
            raise ValueError(f"Réservation {booking_id} non trouvée")

        if db_booking.status != BookingStatus.CONFIRMED:
            raise ValueError(
                f"Vérification possible uniquement pour les réservations confirmées. "
                f"Statut actuel: {db_booking.status.value}"
            )

        if db_booking.is_boarded:
            return BoardingResponse(
                booking_id=db_booking.id,
                passenger_id=db_booking.passenger_id,
                is_boarded=True,
                boarded_at=db_booking.boarded_at,
                boarding_method=db_booking.boarding_method,
                message="Ce passager a déjà été vérifié",
            )

        # Vérifier que le code correspond
        if db_booking.boarding_code != request.code:
            raise ValueError("Code d'embarquement incorrect")

        # Marquer comme embarqué
        db_booking.is_boarded = True
        db_booking.boarded_at = datetime.utcnow()
        db_booking.boarding_method = request.method
        db_booking.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(db_booking)

        return BoardingResponse(
            booking_id=db_booking.id,
            passenger_id=db_booking.passenger_id,
            is_boarded=True,
            boarded_at=db_booking.boarded_at,
            boarding_method=db_booking.boarding_method,
            message="Passager vérifié avec succès !",
        )

    @staticmethod
    def get_trip_boarding_status(db: Session, trip_id: UUID) -> dict:
        """
        Récupère le statut d'embarquement de tous les passagers
        confirmés pour un trajet. Utile pour le tableau de bord chauffeur.
        """
        bookings = db.query(Booking).filter(
            Booking.trip_id == trip_id,
            Booking.status == BookingStatus.CONFIRMED,
        ).all()

        passengers = []
        for b in bookings:
            passengers.append({
                "booking_id": str(b.id),
                "passenger_id": str(b.passenger_id),
                "is_boarded": b.is_boarded,
                "boarded_at": b.boarded_at.isoformat() if b.boarded_at else None,
                "boarding_method": b.boarding_method,
                "pickup_location": b.pickup_location,
            })

        total = len(passengers)
        boarded = sum(1 for p in passengers if p["is_boarded"])

        return {
            "trip_id": str(trip_id),
            "total_confirmed": total,
            "total_boarded": boarded,
            "all_boarded": total > 0 and boarded == total,
            "passengers": passengers,
        }
