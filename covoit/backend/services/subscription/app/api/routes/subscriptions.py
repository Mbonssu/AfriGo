from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional
from pydantic import BaseModel
from app.db.session import get_db
from app.models.subscription import Plan, Subscription, PlanType, SubscriptionStatus
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class SubscribeRequest(BaseModel):
    user_id: str
    plan_type: str  # monthly, quarterly, yearly
    payment_reference: Optional[str] = None


def _serialize_plan(p: Plan) -> dict:
    return {
        "id": str(p.id),
        "name": p.name,
        "plan_type": p.plan_type.value,
        "price": p.price,
        "duration_days": p.duration_days,
        "description": p.description,
        "savings": p.savings,
        "is_highlighted": p.is_highlighted,
    }


def _serialize_sub(s: Subscription) -> dict:
    return {
        "id": str(s.id),
        "user_id": str(s.user_id),
        "plan_type": s.plan_type.value,
        "status": s.status.value,
        "amount_paid": s.amount_paid,
        "payment_reference": s.payment_reference,
        "started_at": s.started_at.isoformat() if s.started_at else None,
        "expires_at": s.expires_at.isoformat() if s.expires_at else None,
        "cancelled_at": s.cancelled_at.isoformat() if s.cancelled_at else None,
        "created_at": s.created_at.isoformat(),
    }


@router.get("/plans")
async def get_plans(db: Session = Depends(get_db)):
    """Récupère tous les plans d'abonnement Prime."""
    plans = db.query(Plan).all()
    return {"data": [_serialize_plan(p) for p in plans]}


@router.post("/subscribe", status_code=201)
async def subscribe(req: SubscribeRequest, db: Session = Depends(get_db)):
    """Crée un abonnement Prime."""
    plan = db.query(Plan).filter(Plan.plan_type == PlanType(req.plan_type)).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan non trouvé")

    # Vérifier s'il y a déjà un abonnement actif
    active = (
        db.query(Subscription)
        .filter(
            Subscription.user_id == UUID(req.user_id),
            Subscription.status == SubscriptionStatus.active,
        )
        .first()
    )
    if active:
        raise HTTPException(status_code=409, detail="Abonnement actif existant")

    now = datetime.utcnow()
    sub = Subscription(
        user_id=UUID(req.user_id),
        plan_type=PlanType(req.plan_type),
        status=SubscriptionStatus.active,
        amount_paid=plan.price,
        payment_reference=req.payment_reference,
        started_at=now,
        expires_at=now + timedelta(days=plan.duration_days),
    )
    db.add(sub)
    db.commit()
    db.refresh(sub)
    return _serialize_sub(sub)


@router.get("/user/{user_id}")
async def get_user_subscription(user_id: str, db: Session = Depends(get_db)):
    """Récupère l'abonnement actif d'un utilisateur."""
    sub = (
        db.query(Subscription)
        .filter(
            Subscription.user_id == UUID(user_id),
            Subscription.status == SubscriptionStatus.active,
        )
        .first()
    )
    if not sub:
        return {"data": None, "is_prime": False}

    # Vérifier si expiré
    if sub.expires_at and sub.expires_at < datetime.utcnow():
        sub.status = SubscriptionStatus.expired
        db.commit()
        return {"data": _serialize_sub(sub), "is_prime": False}

    return {"data": _serialize_sub(sub), "is_prime": True}


@router.get("/user/{user_id}/history")
async def get_subscription_history(user_id: str, db: Session = Depends(get_db)):
    """Historique des abonnements d'un utilisateur."""
    subs = (
        db.query(Subscription)
        .filter(Subscription.user_id == UUID(user_id))
        .order_by(desc(Subscription.created_at))
        .all()
    )
    return {"data": [_serialize_sub(s) for s in subs]}


@router.put("/user/{user_id}/cancel")
async def cancel_subscription(user_id: str, db: Session = Depends(get_db)):
    """Annule l'abonnement actif."""
    sub = (
        db.query(Subscription)
        .filter(
            Subscription.user_id == UUID(user_id),
            Subscription.status == SubscriptionStatus.active,
        )
        .first()
    )
    if not sub:
        raise HTTPException(status_code=404, detail="Aucun abonnement actif")

    sub.status = SubscriptionStatus.cancelled
    sub.cancelled_at = datetime.utcnow()
    db.commit()
    return {"message": "Abonnement annulé"}
