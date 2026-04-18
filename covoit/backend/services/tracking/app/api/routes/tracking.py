from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import asc
from uuid import UUID
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
from app.db.session import get_db
from app.models.tracking import TripTracking, TripStep, TripTrackingStatus
from app.core.redis_client import publish_event
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class StartTrackingRequest(BaseModel):
    trip_id: str
    driver_id: str
    steps: List[dict]  # [{label, city, estimated_time, order_index}]


class UpdatePositionRequest(BaseModel):
    lat: float
    lng: float
    progress: float  # 0.0 → 1.0
    current_step: Optional[str] = None


class UpdateStepRequest(BaseModel):
    status: str  # done, current, pending
    actual_time: Optional[str] = None


def _serialize_tracking(t: TripTracking) -> dict:
    return {
        "id": str(t.id),
        "trip_id": str(t.trip_id),
        "driver_id": str(t.driver_id),
        "status": t.status.value,
        "current_lat": t.current_lat,
        "current_lng": t.current_lng,
        "progress": t.progress,
        "current_step": t.current_step,
        "started_at": t.started_at.isoformat() if t.started_at else None,
        "completed_at": t.completed_at.isoformat() if t.completed_at else None,
        "updated_at": t.updated_at.isoformat() if t.updated_at else None,
    }


def _serialize_step(s: TripStep) -> dict:
    return {
        "id": str(s.id),
        "trip_id": str(s.trip_id),
        "label": s.label,
        "city": s.city,
        "estimated_time": s.estimated_time,
        "actual_time": s.actual_time,
        "status": s.status,
        "order_index": s.order_index,
    }


@router.post("/start", status_code=201)
async def start_tracking(req: StartTrackingRequest, db: Session = Depends(get_db)):
    """Démarre le suivi d'un trajet."""
    existing = db.query(TripTracking).filter(TripTracking.trip_id == UUID(req.trip_id)).first()
    if existing:
        raise HTTPException(status_code=409, detail="Suivi déjà démarré pour ce trajet")

    tracking = TripTracking(
        trip_id=UUID(req.trip_id),
        driver_id=UUID(req.driver_id),
        status=TripTrackingStatus.in_progress,
        started_at=datetime.utcnow(),
    )
    db.add(tracking)

    for step_data in req.steps:
        step = TripStep(
            trip_id=UUID(req.trip_id),
            label=step_data.get("label", ""),
            city=step_data.get("city", ""),
            estimated_time=step_data.get("estimated_time"),
            order_index=step_data.get("order_index", 0),
        )
        db.add(step)

    db.commit()
    db.refresh(tracking)
    return _serialize_tracking(tracking)


@router.get("/trip/{trip_id}")
async def get_tracking(trip_id: str, db: Session = Depends(get_db)):
    """Récupère le suivi d'un trajet avec ses étapes."""
    tracking = db.query(TripTracking).filter(TripTracking.trip_id == UUID(trip_id)).first()
    if not tracking:
        raise HTTPException(status_code=404, detail="Suivi non trouvé")

    steps = (
        db.query(TripStep)
        .filter(TripStep.trip_id == UUID(trip_id))
        .order_by(asc(TripStep.order_index))
        .all()
    )

    result = _serialize_tracking(tracking)
    result["steps"] = [_serialize_step(s) for s in steps]
    return result


@router.put("/trip/{trip_id}/position")
async def update_position(trip_id: str, req: UpdatePositionRequest, db: Session = Depends(get_db)):
    """Met à jour la position GPS du chauffeur."""
    tracking = db.query(TripTracking).filter(TripTracking.trip_id == UUID(trip_id)).first()
    if not tracking:
        raise HTTPException(status_code=404, detail="Suivi non trouvé")

    tracking.current_lat = req.lat
    tracking.current_lng = req.lng
    tracking.progress = req.progress
    if req.current_step:
        tracking.current_step = req.current_step
    tracking.updated_at = datetime.utcnow()
    db.commit()

    serialized = _serialize_tracking(tracking)
    publish_event(f"tracking:{trip_id}", {"type": "position_update", "tracking": serialized})
    return serialized


@router.put("/trip/{trip_id}/step/{step_id}")
async def update_step(trip_id: str, step_id: str, req: UpdateStepRequest, db: Session = Depends(get_db)):
    """Met à jour le statut d'une étape du voyage."""
    step = db.query(TripStep).filter(TripStep.id == UUID(step_id), TripStep.trip_id == UUID(trip_id)).first()
    if not step:
        raise HTTPException(status_code=404, detail="Étape non trouvée")

    step.status = req.status
    if req.actual_time:
        step.actual_time = req.actual_time
    db.commit()
    return _serialize_step(step)


@router.put("/trip/{trip_id}/complete")
async def complete_tracking(trip_id: str, db: Session = Depends(get_db)):
    """Marque le suivi comme terminé."""
    tracking = db.query(TripTracking).filter(TripTracking.trip_id == UUID(trip_id)).first()
    if not tracking:
        raise HTTPException(status_code=404, detail="Suivi non trouvé")

    tracking.status = TripTrackingStatus.completed
    tracking.progress = 1.0
    tracking.completed_at = datetime.utcnow()
    db.commit()
    return _serialize_tracking(tracking)


# ── Envoi de position de sécurité (contact d'urgence) ────────────────────────

class SafetyLocationRequest(BaseModel):
    user_id: str
    lat: float
    lng: float
    user_name: str = "Utilisateur"
    trip_from: str = ""
    trip_to: str = ""
    emergency_contact_name: str = ""
    emergency_contact_phone: str = ""

@router.post("/trip/{trip_id}/safety-location")
async def send_safety_location(trip_id: str, req: SafetyLocationRequest, db: Session = Depends(get_db)):
    """Reçoit la position GPS et publie un événement pour notifier le contact d'urgence."""
    tracking = db.query(TripTracking).filter(TripTracking.trip_id == UUID(trip_id)).first()
    if not tracking:
        raise HTTPException(status_code=404, detail="Suivi non trouvé")

    if not req.emergency_contact_phone:
        return {"status": "skipped", "reason": "Aucun contact d'urgence configuré"}

    maps_url = f"https://www.google.com/maps?q={req.lat},{req.lng}"

    # Message SMS destiné au contact d'urgence
    sms_message = (
        f"[237COVOIT Sécurité] {req.user_name} est en voyage "
        f"{req.trip_from} → {req.trip_to}. "
        f"Position actuelle : {maps_url}"
    )

    publish_event("safety:location", {
        "type": "safety_location",
        "trip_id": trip_id,
        "user_id": req.user_id,
        "user_name": req.user_name,
        "lat": req.lat,
        "lng": req.lng,
        "maps_url": maps_url,
        "trip_from": req.trip_from,
        "trip_to": req.trip_to,
        "emergency_contact_name": req.emergency_contact_name,
        "emergency_contact_phone": req.emergency_contact_phone,
        "sms_message": sms_message,
        "timestamp": datetime.utcnow().isoformat(),
    })
    logger.info(
        f"Safety location for trip {trip_id}: "
        f"{req.lat},{req.lng} → SMS to {req.emergency_contact_phone} ({req.emergency_contact_name})"
    )
    return {"status": "sent", "maps_url": maps_url, "sent_to": req.emergency_contact_phone}
