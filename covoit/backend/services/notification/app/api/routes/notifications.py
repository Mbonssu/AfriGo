from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.db.session import get_db
from app.models.notification import Notification
from app.core.redis_client import publish_event
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class NotificationCreate(BaseModel):
    user_id: str
    title: str = Field(..., max_length=200)
    body: str
    icon: str = "info"
    action_type: Optional[str] = None
    action_id: Optional[str] = None


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    body: str
    icon: str
    is_read: bool
    action_type: Optional[str]
    action_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


@router.get("/user/{user_id}")
async def get_user_notifications(
    user_id: str,
    limit: int = Query(default=50, le=100),
    db: Session = Depends(get_db),
):
    notifications = (
        db.query(Notification)
        .filter(Notification.user_id == UUID(user_id))
        .order_by(desc(Notification.created_at))
        .limit(limit)
        .all()
    )
    unread_count = (
        db.query(Notification)
        .filter(Notification.user_id == UUID(user_id), Notification.is_read == False)
        .count()
    )
    return {
        "data": [
            {
                "id": str(n.id),
                "user_id": str(n.user_id),
                "title": n.title,
                "body": n.body,
                "icon": n.icon,
                "is_read": n.is_read,
                "action_type": n.action_type,
                "action_id": n.action_id,
                "created_at": n.created_at.isoformat(),
            }
            for n in notifications
        ],
        "unread_count": unread_count,
    }


@router.post("", status_code=201)
async def create_notification(req: NotificationCreate, db: Session = Depends(get_db)):
    notif = Notification(
        user_id=UUID(req.user_id),
        title=req.title,
        body=req.body,
        icon=req.icon,
        action_type=req.action_type,
        action_id=req.action_id,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    publish_event(f"notifications:{req.user_id}", {
        "type": "new_notification",
        "notification": {
            "id": str(notif.id),
            "title": notif.title,
            "body": notif.body,
            "icon": notif.icon,
            "action_type": notif.action_type,
            "action_id": notif.action_id,
            "created_at": notif.created_at.isoformat(),
        },
    })
    return {"id": str(notif.id), "message": "Notification créée"}


@router.put("/{notification_id}/read")
async def mark_as_read(notification_id: str, db: Session = Depends(get_db)):
    notif = db.query(Notification).filter(Notification.id == UUID(notification_id)).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification non trouvée")
    notif.is_read = True
    db.commit()
    return {"message": "Notification marquée comme lue"}


@router.put("/user/{user_id}/read-all")
async def mark_all_as_read(user_id: str, db: Session = Depends(get_db)):
    db.query(Notification).filter(
        Notification.user_id == UUID(user_id), Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"message": "Toutes les notifications marquées comme lues"}
