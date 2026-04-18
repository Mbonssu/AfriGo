from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.db.session import get_db
from app.models.caution import Caution, CautionStatus, CautionType
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class CautionCreate(BaseModel):
    user_id: str
    booking_id: Optional[str] = None
    trip_id: Optional[str] = None
    trip_route: str
    amount: int = 500
    caution_type: str  # passenger, driver
    reason: Optional[str] = None


def _serialize(c: Caution) -> dict:
    return {
        "id": str(c.id),
        "user_id": str(c.user_id),
        "booking_id": str(c.booking_id) if c.booking_id else None,
        "trip_id": str(c.trip_id) if c.trip_id else None,
        "trip_route": c.trip_route,
        "amount": c.amount,
        "caution_type": c.caution_type.value,
        "status": c.status.value,
        "reason": c.reason,
        "created_at": c.created_at.isoformat(),
        "resolved_at": c.resolved_at.isoformat() if c.resolved_at else None,
    }


@router.get("/user/{user_id}")
async def get_user_cautions(
    user_id: str,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Récupère les cautions d'un utilisateur, optionnellement filtrées par statut."""
    query = db.query(Caution).filter(Caution.user_id == UUID(user_id))
    if status:
        query = query.filter(Caution.status == CautionStatus(status))
    cautions = query.order_by(desc(Caution.created_at)).all()
    return {"data": [_serialize(c) for c in cautions]}


@router.get("/user/{user_id}/summary")
async def get_caution_summary(user_id: str, db: Session = Depends(get_db)):
    """Résumé des cautions : montants en attente, remboursés, retenus."""
    uid = UUID(user_id)

    def _sum(s: CautionStatus) -> int:
        result = (
            db.query(func.coalesce(func.sum(Caution.amount), 0))
            .filter(Caution.user_id == uid, Caution.status == s)
            .scalar()
        )
        return int(result)

    return {
        "pending": _sum(CautionStatus.pending),
        "refunded": _sum(CautionStatus.refunded),
        "retained": _sum(CautionStatus.retained),
    }


@router.post("", status_code=201)
async def create_caution(req: CautionCreate, db: Session = Depends(get_db)):
    """Crée une nouvelle caution."""
    caution = Caution(
        user_id=UUID(req.user_id),
        booking_id=UUID(req.booking_id) if req.booking_id else None,
        trip_id=UUID(req.trip_id) if req.trip_id else None,
        trip_route=req.trip_route,
        amount=req.amount,
        caution_type=CautionType(req.caution_type),
        reason=req.reason or "Réservation confirmée — caution bloquée",
    )
    db.add(caution)
    db.commit()
    db.refresh(caution)
    return _serialize(caution)


@router.put("/{caution_id}/refund")
async def refund_caution(caution_id: str, db: Session = Depends(get_db)):
    """Rembourse une caution."""
    caution = db.query(Caution).filter(Caution.id == UUID(caution_id)).first()
    if not caution:
        raise HTTPException(status_code=404, detail="Caution non trouvée")
    if caution.status != CautionStatus.pending:
        raise HTTPException(status_code=400, detail="Caution déjà résolue")

    caution.status = CautionStatus.refunded
    caution.reason = caution.reason or "Voyage terminé avec succès"
    caution.resolved_at = datetime.utcnow()
    db.commit()
    return {"message": "Caution remboursée"}


@router.put("/{caution_id}/retain")
async def retain_caution(
    caution_id: str,
    reason: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Retient une caution (annulation passager, etc)."""
    caution = db.query(Caution).filter(Caution.id == UUID(caution_id)).first()
    if not caution:
        raise HTTPException(status_code=404, detail="Caution non trouvée")
    if caution.status != CautionStatus.pending:
        raise HTTPException(status_code=400, detail="Caution déjà résolue")

    caution.status = CautionStatus.retained
    if reason:
        caution.reason = reason
    caution.resolved_at = datetime.utcnow()
    db.commit()
    return {"message": "Caution retenue"}
