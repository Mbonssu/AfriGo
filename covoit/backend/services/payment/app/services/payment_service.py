# Import de SqlAlchemy pour les requêtes à la base de données
import json
import logging
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from datetime import datetime
from uuid import UUID
from typing import Optional, List, Tuple

# Import des modèles SQLAlchemy
from app.models.payment import Payment, PaymentTransaction, PaymentStatus, PaymentType, PaymentMethod

# Import des schémas Pydantic
from app.schemas.payment import (
    MonetbilPaymentInitiateRequest,
    MonetbilPaymentInitiateResponse,
    MonetbilPaymentVerifyRequest,
    MonetbilPaymentVerifyResponse,
    PaymentStatusSchema,
    PaymentCreateRequest,
    PaymentStatusUpdateRequest,
    PaymentResponse,
    PaymentSearchRequest,
    PaymentSearchResponse,
    RefundRequest,
    RefundResponse,
)
from app.core.config import settings
from app.services.monetbil_client import MonetbilClient, MonetbilClientError

logger = logging.getLogger(__name__)

class PaymentService:
    """
    Service métier pour gérer tous les paiements.
    Contient la logique pour créer, rechercher, mettre à jour les paiements.
    """

    @staticmethod
    def initiate_monetbil_payment(
        db: Session,
        request: MonetbilPaymentInitiateRequest,
    ) -> MonetbilPaymentInitiateResponse:
        """Crée un paiement local puis lance une demande Mobile Money Monetbil."""

        payment_request = PaymentCreateRequest(
            user_id=request.user_id,
            booking_id=request.booking_id,
            amount=request.amount,
            payment_method=request.payment_method,
            payment_type=request.payment_type,
            phone_number=PaymentService._normalize_phone(request.phone_number),
        )

        payment = PaymentService.create_payment(db, payment_request)
        db_payment = db.query(Payment).filter(Payment.id == payment.id).first()
        if db_payment is None:
            raise ValueError("Le paiement local n'a pas pu être retrouvé après création.")

        payload = {
            "service": settings.MONETBIL_SERVICE_KEY,
            "amount": request.amount,
            "phonenumber": db_payment.phone_number,
            "operator": PaymentService._monetbil_operator_code(request.payment_method.value),
            "currency": settings.MONETBIL_CURRENCY,
            "country": settings.MONETBIL_COUNTRY,
            "item_ref": request.booking_id.hex if request.booking_id else str(payment.id),
            "payment_ref": str(payment.id),
            "user": str(request.user_id),
        }
        if request.first_name:
            payload["first_name"] = request.first_name
        if request.last_name:
            payload["last_name"] = request.last_name
        if request.email:
            payload["email"] = request.email
        if settings.MONETBIL_NOTIFY_URL:
            payload["notify_url"] = settings.MONETBIL_NOTIFY_URL

        try:
            provider_response = MonetbilClient.place_payment(payload)
        except MonetbilClientError as exc:
            PaymentService._set_payment_status(
                db,
                db_payment,
                status=PaymentStatus.FAILED,
                provider_response={"error": str(exc), "payload": payload},
                error_message=str(exc),
            )
            raise ValueError(str(exc)) from exc

        provider_status = str(provider_response.get("status") or "UNKNOWN")
        provider_payment_id = str(provider_response.get("paymentId") or "")
        if provider_status != "REQUEST_ACCEPTED" or not provider_payment_id:
            message = str(provider_response.get("message") or "Demande Monetbil refusée")
            PaymentService._set_payment_status(
                db,
                db_payment,
                status=PaymentStatus.FAILED,
                provider_response=provider_response,
                error_message=message,
            )
            raise ValueError(message)

        db_payment.transaction_id = provider_payment_id
        db_payment.updated_at = datetime.utcnow()
        db.add(
            PaymentTransaction(
                payment_id=db_payment.id,
                status=PaymentStatus.PENDING,
                provider_response=PaymentService._compact_json(provider_response),
            )
        )
        db.commit()
        db.refresh(db_payment)

        return MonetbilPaymentInitiateResponse(
            payment_id=db_payment.id,
            provider="monetbil",
            provider_payment_id=provider_payment_id,
            status=PaymentStatusSchema.PENDING,
            provider_status=provider_status,
            message=str(provider_response.get("message") or "Paiement en attente de validation"),
            amount=db_payment.amount,
            payment_method=request.payment_method,
            payment_type=request.payment_type,
            phone_number=db_payment.phone_number,
            channel_name=provider_response.get("channel_name"),
            channel_ussd=provider_response.get("channel_ussd"),
            operator_code=provider_response.get("channel"),
            payment_url=provider_response.get("payment_url"),
        )

    @staticmethod
    def verify_monetbil_payment(
        db: Session,
        request: MonetbilPaymentVerifyRequest,
    ) -> MonetbilPaymentVerifyResponse:
        """Interroge Monetbil pour obtenir le statut réel d'un paiement."""

        db_payment = db.query(Payment).filter(Payment.id == request.payment_id).first()
        if db_payment is None:
            raise ValueError(f"Paiement {request.payment_id} non trouvé")
        if not db_payment.transaction_id:
            raise ValueError("Aucun identifiant Monetbil n'est associé à ce paiement.")

        provider_response = MonetbilClient.check_payment(db_payment.transaction_id)
        transaction = provider_response.get("transaction")
        provider_status = "PENDING"
        local_status = PaymentStatus.PENDING
        message = str(provider_response.get("message") or "Paiement en attente")
        operator_transaction_id = None

        if isinstance(transaction, dict):
            provider_status = str(transaction.get("status"))
            local_status = PaymentService._payment_status_from_monetbil(provider_status)
            message = str(transaction.get("message") or provider_response.get("message") or message)
            operator_transaction_id = (
                transaction.get("transaction_uuid")
                or transaction.get("operator_transaction_id")
                or transaction.get("transaction_id")
            )
            PaymentService._set_payment_status(
                db,
                db_payment,
                status=local_status,
                provider_response=provider_response,
                error_message=None if local_status == PaymentStatus.SUCCESS else message,
            )
        else:
            PaymentService._append_transaction_log(
                db,
                payment_id=db_payment.id,
                status=PaymentStatus.PENDING,
                provider_response=provider_response,
            )

        return MonetbilPaymentVerifyResponse(
            payment_id=db_payment.id,
            provider="monetbil",
            provider_payment_id=db_payment.transaction_id,
            status=PaymentStatusSchema(db_payment.status.value),
            provider_status=provider_status,
            is_final=db_payment.status != PaymentStatus.PENDING,
            message=message,
            operator_transaction_id=operator_transaction_id,
            payment_url=None,
        )

    @staticmethod
    def handle_monetbil_notification(
        db: Session,
        data: dict,
    ) -> MonetbilPaymentVerifyResponse:
        """Met à jour un paiement suite à un callback serveur Monetbil."""

        payment_ref = data.get("payment_ref")
        if not payment_ref:
            raise ValueError("Notification Monetbil invalide: payment_ref manquant.")

        db_payment = db.query(Payment).filter(Payment.id == UUID(str(payment_ref))).first()
        if db_payment is None:
            raise ValueError(f"Paiement {payment_ref} non trouvé")

        local_status = PaymentService._payment_status_from_notification(
            str(data.get("status") or "pending")
        )
        provider_payment_id = str(data.get("transaction_id") or db_payment.transaction_id or "")
        if provider_payment_id:
            db_payment.transaction_id = provider_payment_id

        PaymentService._set_payment_status(
            db,
            db_payment,
            status=local_status,
            provider_response=data,
            error_message=None if local_status == PaymentStatus.SUCCESS else str(data.get("message") or ""),
        )

        return MonetbilPaymentVerifyResponse(
            payment_id=db_payment.id,
            provider="monetbil",
            provider_payment_id=db_payment.transaction_id,
            status=PaymentStatusSchema(db_payment.status.value),
            provider_status=str(data.get("status") or "pending"),
            is_final=db_payment.status != PaymentStatus.PENDING,
            message=str(data.get("message") or "Notification recue"),
            operator_transaction_id=str(data.get("transaction_uuid") or data.get("operator_transaction_id") or ""),
            payment_url=None,
        )
    
    @staticmethod
    def create_payment(db: Session, request: PaymentCreateRequest) -> PaymentResponse:
        """
        Crée un nouveau paiement en base de données.
        
        Paramètres:
            db: Session SQLAlchemy pour les requêtes
            request: Données du paiement à créer (PaymentCreateRequest)
        
        Retour:
            PaymentResponse: Le paiement créé avec son UUID
        
        Exemple d'utilisation:
            >>> payment_req = PaymentCreateRequest(
            ...     user_id=UUID('550e8400-e29b-41d4-a716-446655440000'),
            ...     amount=5000.0,
            ...     payment_method=PaymentMethodSchema.MTN,
            ...     payment_type=PaymentTypeSchema.BOOKING,
            ...     phone_number='+237655123456'
            ... )
            >>> payment = PaymentService.create_payment(db, payment_req)
        """
        
        # Créer l'objet Payment SQLAlchemy
        db_payment = Payment(
            user_id=request.user_id,                          # UUID de l'utilisateur
            booking_id=request.booking_id,                    # UUID de la réservation (optionnel)
            amount=request.amount,                            # Montant en FCFA
            payment_method=PaymentMethod(request.payment_method.value),  # Convertir enum
            payment_type=PaymentType(request.payment_type.value),        # Convertir enum
            phone_number=request.phone_number,                # Numéro de téléphone
            status=PaymentStatus.PENDING,                     # Le paiement démarre en PENDING
        )
        
        # Ajouter à la session et commiter
        db.add(db_payment)
        db.commit()
        
        # Actualiser depuis la base de données (pour récupérer les timestamps)
        db.refresh(db_payment)
        
        # Retourner sous forme de schéma Pydantic
        return PaymentResponse.model_validate(db_payment)

    @staticmethod
    def _normalize_phone(phone_number: str) -> str:
        digits = "".join(ch for ch in phone_number if ch.isdigit())
        if digits.startswith("237"):
            return digits
        if digits.startswith("6") and len(digits) == 9:
            return f"237{digits}"
        if digits.startswith("0"):
            return digits.lstrip("0")
        return digits

    @staticmethod
    def _monetbil_operator_code(payment_method: str) -> str:
        mapping = {
            "mtn": "CM_MTNMOBILEMONEY",
            "orange": "CM_ORANGEMONEY",
        }
        code = mapping.get(payment_method)
        if not code:
            raise ValueError(f"Methode Monetbil non supportee: {payment_method}")
        return code

    @staticmethod
    def _payment_status_from_monetbil(provider_status: str) -> PaymentStatus:
        mapping = {
            "1": PaymentStatus.SUCCESS,
            "0": PaymentStatus.FAILED,
            "-1": PaymentStatus.CANCELLED,
            "-2": PaymentStatus.REFUNDED,
        }
        return mapping.get(str(provider_status), PaymentStatus.PENDING)

    @staticmethod
    def _payment_status_from_notification(provider_status: str) -> PaymentStatus:
        mapping = {
            "success": PaymentStatus.SUCCESS,
            "failed": PaymentStatus.FAILED,
            "cancelled": PaymentStatus.CANCELLED,
            "refunded": PaymentStatus.REFUNDED,
        }
        return mapping.get(provider_status.lower(), PaymentStatus.PENDING)

    @staticmethod
    def _compact_json(payload: object) -> str:
        try:
            return json.dumps(payload, ensure_ascii=False)[:1900]
        except Exception:
            return str(payload)[:1900]

    @staticmethod
    def _append_transaction_log(
        db: Session,
        *,
        payment_id: UUID,
        status: PaymentStatus,
        provider_response: object,
        error_message: Optional[str] = None,
    ) -> None:
        db.add(
            PaymentTransaction(
                payment_id=payment_id,
                status=status,
                error_message=error_message,
                provider_response=PaymentService._compact_json(provider_response),
            )
        )
        db.commit()

    @staticmethod
    def _set_payment_status(
        db: Session,
        db_payment: Payment,
        *,
        status: PaymentStatus,
        provider_response: object,
        error_message: Optional[str] = None,
    ) -> None:
        db_payment.status = status
        db_payment.updated_at = datetime.utcnow()
        db.add(db_payment)
        db.add(
            PaymentTransaction(
                payment_id=db_payment.id,
                status=status,
                error_message=error_message,
                provider_response=PaymentService._compact_json(provider_response),
            )
        )
        db.commit()
        db.refresh(db_payment)
    
    @staticmethod
    def get_payment_by_id(db: Session, payment_id: UUID) -> Optional[PaymentResponse]:
        """
        Récupère un paiement par son UUID.
        
        Paramètres:
            db: Session SQLAlchemy
            payment_id: UUID du paiement à récupérer
        
        Retour:
            PaymentResponse ou None si non trouvé
        
        Exemple:
            >>> payment = PaymentService.get_payment_by_id(db, UUID('550e8400-e29b-41d4-a716-446655440000'))
            >>> if payment:
            ...     print(f"Montant: {payment.amount} FCFA")
        """
        
        # Requête: SELECT * FROM payments WHERE id = payment_id LIMIT 1
        db_payment = db.query(Payment).filter(Payment.id == payment_id).first()
        
        # Retourner None si pas trouvé, sinon convertir en schéma
        if db_payment is None:
            return None
        
        return PaymentResponse.model_validate(db_payment)
    
    @staticmethod
    def get_user_payments(
        db: Session,
        user_id: UUID,
        limit: int = 20,
        offset: int = 0
    ) -> PaymentSearchResponse:
        """
        Récupère tous les paiements d'un utilisateur avec pagination.
        
        Paramètres:
            db: Session SQLAlchemy
            user_id: UUID de l'utilisateur
            limit: Nombre maximum de résultats (défaut 20)
            offset: Décalage pour pagination (défaut 0)
        
        Retour:
            PaymentSearchResponse: Liste paginée des paiements
        
        Exemple:
            >>> result = PaymentService.get_user_payments(
            ...     db,
            ...     UUID('550e8400-e29b-41d4-a716-446655440000'),
            ...     limit=10,
            ...     offset=0
            ... )
            >>> print(f"Total: {result.total}, Résultats: {result.count}")
        """
        
        # Requête pour compter le total des paiements de l'utilisateur
        # COUNT(*) WHERE user_id = ?
        total = db.query(Payment).filter(Payment.user_id == user_id).count()
        
        # Requête pour récupérer une page de paiements
        # SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC LIMIT limit OFFSET offset
        payments = db.query(Payment).filter(
            Payment.user_id == user_id
        ).order_by(
            Payment.created_at.desc()  # Les plus récents d'abord
        ).limit(limit).offset(offset).all()
        
        # Convertir chaque objet Payment en PaymentResponse
        payment_list = [PaymentResponse.model_validate(p) for p in payments]
        
        # Retourner la réponse avec métadonnées de pagination
        return PaymentSearchResponse(
            data=payment_list,
            total=total,
            count=len(payment_list),
            offset=offset,
            limit=limit,
        )
    
    @staticmethod
    def search_payments(
        db: Session,
        request: PaymentSearchRequest
    ) -> PaymentSearchResponse:
        """
        Recherche les paiements avec filtres multiples.
        
        Filtres supportés:
        - user_id: Utilisateur qui a payé
        - status: Statut (pending, success, failed, etc.)
        - payment_type: Type (booking, caution, subscription)
        - payment_method: Méthode (mtn, orange)
        - min_amount / max_amount: Plage de montants
        
        Paramètres:
            db: Session SQLAlchemy
            request: Critères de recherche (PaymentSearchRequest)
        
        Retour:
            PaymentSearchResponse: Résultats filtrés et paginés
        
        Exemple:
            >>> search = PaymentSearchRequest(
            ...     user_id=UUID('550e8400-e29b-41d4-a716-446655440000'),
            ...     status=PaymentStatusSchema.SUCCESS,
            ...     limit=50
            ... )
            >>> result = PaymentService.search_payments(db, search)
        """
        
        # Construire la requête de base
        query = db.query(Payment)
        
        # Appliquer les filtres progressivement
        
        # Filtrer par utilisateur si fourni
        if request.user_id:
            query = query.filter(Payment.user_id == request.user_id)
        
        # Filtrer par statut si fourni
        if request.status:
            query = query.filter(Payment.status == PaymentStatus(request.status.value))
        
        # Filtrer par type si fourni
        if request.payment_type:
            query = query.filter(Payment.payment_type == PaymentType(request.payment_type.value))
        
        # Filtrer par méthode si fournie
        if request.payment_method:
            query = query.filter(Payment.payment_method == PaymentMethod(request.payment_method.value))
        
        # Filtrer par montant minimum si fourni
        if request.min_amount is not None:
            query = query.filter(Payment.amount >= request.min_amount)
        
        # Filtrer par montant maximum si fourni
        if request.max_amount is not None:
            query = query.filter(Payment.amount <= request.max_amount)
        
        # Compter le total AVANT d'appliquer limit/offset
        total = query.count()
        
        # Appliquer le tri (les plus récents d'abord)
        query = query.order_by(Payment.created_at.desc())
        
        # Appliquer la pagination
        payments = query.limit(request.limit).offset(request.offset).all()
        
        # Convertir les résultats
        payment_list = [PaymentResponse.model_validate(p) for p in payments]
        
        # Retourner la réponse paginée
        return PaymentSearchResponse(
            data=payment_list,
            total=total,
            count=len(payment_list),
            offset=request.offset,
            limit=request.limit,
        )
    
    @staticmethod
    def update_payment_status(
        db: Session,
        payment_id: UUID,
        request: PaymentStatusUpdateRequest
    ) -> PaymentResponse:
        """
        Met à jour le statut d'un paiement.
        Appelé lorsqu'on reçoit une notification du prestataire (MTN/Orange).
        
        Paramètres:
            db: Session SQLAlchemy
            payment_id: UUID du paiement à mettre à jour
            request: Nouveau statut et détails (PaymentStatusUpdateRequest)
        
        Retour:
            PaymentResponse: Le paiement mis à jour
        
        Lève une exception:
            ValueError: Si le paiement n'existe pas
        
        Exemple:
            >>> update = PaymentStatusUpdateRequest(
            ...     status=PaymentStatusSchema.SUCCESS,
            ...     transaction_id="TXN123456789"
            ... )
            >>> payment = PaymentService.update_payment_status(db, payment_id, update)
        """
        
        # Récupérer le paiement
        db_payment = db.query(Payment).filter(Payment.id == payment_id).first()
        
        # Vérifier que le paiement existe
        if db_payment is None:
            raise ValueError(f"Paiement {payment_id} non trouvé")
        
        # Mettre à jour les champs
        db_payment.status = PaymentStatus(request.status.value)  # Nouveau statut
        db_payment.transaction_id = request.transaction_id       # ID du prestataire
        db_payment.updated_at = datetime.utcnow()               # Timestamp actuel
        
        # Créer un enregistrement dans l'historique
        if request.provider_response:
            transaction_history = PaymentTransaction(
                payment_id=payment_id,
                status=PaymentStatus(request.status.value),
                provider_response=request.provider_response,
            )
            db.add(transaction_history)
        
        # Sauvegarder les changements
        db.commit()
        db.refresh(db_payment)
        
        # Retourner le paiement mis à jour
        return PaymentResponse.model_validate(db_payment)
    
    @staticmethod
    def cancel_payment(db: Session, payment_id: UUID) -> PaymentResponse:
        """
        Annule un paiement (change son statut à CANCELLED).
        Utilisé quand l'utilisateur annule avant que le paiement soit complété.
        
        Paramètres:
            db: Session SQLAlchemy
            payment_id: UUID du paiement à annuler
        
        Retour:
            PaymentResponse: Le paiement annulé
        
        Lève une exception:
            ValueError: Si le paiement est déjà complété
        
        Exemple:
            >>> cancelled = PaymentService.cancel_payment(db, payment_id)
        """
        
        # Récupérer le paiement
        db_payment = db.query(Payment).filter(Payment.id == payment_id).first()
        
        if db_payment is None:
            raise ValueError(f"Paiement {payment_id} non trouvé")
        
        # Vérifier que le paiement peut être annulé (pas déjà SUCCESS)
        if db_payment.status == PaymentStatus.SUCCESS:
            raise ValueError("Impossible d'annuler un paiement réussi. Demander un remboursement à la place.")
        
        # Mettre à jour le statut
        db_payment.status = PaymentStatus.CANCELLED
        db_payment.updated_at = datetime.utcnow()
        
        # Sauvegarder
        db.commit()
        db.refresh(db_payment)
        
        # Retourner le paiement annulé
        return PaymentResponse.model_validate(db_payment)
    
    @staticmethod
    def refund_payment(
        db: Session,
        payment_id: UUID,
        request: RefundRequest
    ) -> Tuple[PaymentResponse, bool]:
        """
        Lance un remboursement pour un paiement déjà réussi.
        
        Paramètres:
            db: Session SQLAlchemy
            payment_id: UUID du paiement à rembourser
            request: Détails du remboursement (RefundRequest)
        
        Retour:
            Tuple[PaymentResponse, bool]: (Paiement mis à jour, succès du remboursement)
            - bool = True si remboursement lancé avec succès
            - bool = False si remboursement échoué
        
        Lève une exception:
            ValueError: Si le paiement n'existe pas ou n'est pas réussi
        
        Exemple:
            >>> refund_req = RefundRequest(
            ...     reason="Utilisateur a annulé la réservation",
            ...     partial_amount=None  # Remboursement complet
            ... )
            >>> payment, success = PaymentService.refund_payment(db, payment_id, refund_req)
        """
        
        # Récupérer le paiement
        db_payment = db.query(Payment).filter(Payment.id == payment_id).first()
        
        if db_payment is None:
            raise ValueError(f"Paiement {payment_id} non trouvé")
        
        # Vérifier que c'est un paiement réussi
        if db_payment.status != PaymentStatus.SUCCESS:
            raise ValueError(
                f"Seuls les paiements réussis peuvent être remboursés. "
                f"Statut actuel: {db_payment.status.value}"
            )
        
        # Vérifier que le montant n'est pas déjà remboursé
        if db_payment.status == PaymentStatus.REFUNDED:
            raise ValueError("Ce paiement a déjà été remboursé")
        
        # Déterminer le montant à rembourser
        refund_amount = request.partial_amount if request.partial_amount else db_payment.amount
        
        # Vérifier que le montant partiel ne dépasse pas le montant total
        if request.partial_amount and request.partial_amount > db_payment.amount:
            raise ValueError(
                f"Le montant du remboursement partiel ({request.partial_amount}) "
                f"ne peut pas dépasser le montant total ({db_payment.amount})"
            )
        
        # Changer le statut à REFUNDED
        db_payment.status = PaymentStatus.REFUNDED
        db_payment.updated_at = datetime.utcnow()
        
        # Sauvegarder la demande de remboursement
        db.commit()
        db.refresh(db_payment)
        
        # NOTE: Dans une implémentation réelle, il faudrait:
        # 1. Appeler l'API du prestataire (MTN/Orange) pour traiter le remboursement
        # 2. Attendre la confirmation du préstataire
        # 3. Mettre à jour le statut en fonction de la réponse
        # Pour cet exemple, on retourne True (succès supposé)
        
        return PaymentResponse.model_validate(db_payment), True
    
    @staticmethod
    def get_payment_statistics(
        db: Session,
        user_id: Optional[UUID] = None,
        payment_type: Optional[str] = None
    ) -> dict:
        """
        Calcule des statistiques sur les paiements.
        Utile pour afficher les graphiques et rapports.
        
        Paramètres:
            db: Session SQLAlchemy
            user_id: UUID de l'utilisateur (optionnel)
            payment_type: Type de paiement (optionnel)
        
        Retour:
            dict: Dictionnaire avec statistiques:
            {
                "total_amount": 50000.0,
                "total_count": 5,
                "success_count": 4,
                "failed_count": 1,
                "success_rate": 80.0,
                "average_amount": 10000.0
            }
        
        Exemple:
            >>> stats = PaymentService.get_payment_statistics(
            ...     db,
            ...     user_id=UUID('550e8400-e29b-41d4-a716-446655440000')
            ... )
        """
        
        # Construire la requête de base
        query = db.query(Payment)
        
        # Appliquer les filtres si fournis
        if user_id:
            query = query.filter(Payment.user_id == user_id)
        
        if payment_type:
            query = query.filter(Payment.payment_type == PaymentType(payment_type))
        
        # Obtenir tous les paiements pour les statistiques
        payments = query.all()
        
        if not payments:
            # Retourner des zéros si pas de paiements
            return {
                "total_amount": 0.0,
                "total_count": 0,
                "success_count": 0,
                "failed_count": 0,
                "pending_count": 0,
                "cancelled_count": 0,
                "refunded_count": 0,
                "success_rate": 0.0,
                "average_amount": 0.0,
            }
        
        # Calculer les statistiques
        total_count = len(payments)                                          # Nombre total
        total_amount = sum(p.amount for p in payments)                       # Somme totale
        success_count = sum(1 for p in payments if p.status == PaymentStatus.SUCCESS)  # Réussis
        failed_count = sum(1 for p in payments if p.status == PaymentStatus.FAILED)    # Échoués
        pending_count = sum(1 for p in payments if p.status == PaymentStatus.PENDING)  # En attente
        cancelled_count = sum(1 for p in payments if p.status == PaymentStatus.CANCELLED)  # Annulés
        refunded_count = sum(1 for p in payments if p.status == PaymentStatus.REFUNDED)    # Remboursés
        
        # Calculer le taux de succès
        success_rate = (success_count / total_count * 100) if total_count > 0 else 0
        
        # Calculer la moyenne
        average_amount = total_amount / total_count if total_count > 0 else 0
        
        # Retourner le dictionnaire de statistiques
        return {
            "total_amount": total_amount,
            "total_count": total_count,
            "success_count": success_count,
            "failed_count": failed_count,
            "pending_count": pending_count,
            "cancelled_count": cancelled_count,
            "refunded_count": refunded_count,
            "success_rate": round(success_rate, 2),
            "average_amount": round(average_amount, 2),
        }
