from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, or_, and_
from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.db.session import get_db
from app.models.chat import ChatRoom, Message
from app.core.redis_client import publish_event
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class RoomCreate(BaseModel):
    trip_id: str
    participant_1: str
    participant_2: str


class MessageCreate(BaseModel):
    sender_id: UUID
    content: str = Field(..., min_length=1, max_length=1000)

    @field_validator("content")
    @classmethod
    def normalize_content(cls, value: str) -> str:
        return value.strip()


class MessageResponse(BaseModel):
    id: str
    room_id: str
    sender_id: str
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


def _serialize_message(m: Message) -> dict:
    return {
        "id": str(m.id),
        "room_id": str(m.room_id),
        "sender_id": str(m.sender_id),
        "content": m.content,
        "is_read": m.is_read,
        "created_at": m.created_at.isoformat(),
    }


@router.get("/room/trip/{trip_id}/users/{user1_id}/{user2_id}")
async def get_or_create_room(trip_id: str, user1_id: str, user2_id: str, db: Session = Depends(get_db)):
    """Récupère ou crée une room de chat pour un trip entre 2 users."""
    room = (
        db.query(ChatRoom)
        .filter(
            ChatRoom.trip_id == UUID(trip_id),
            or_(
                and_(ChatRoom.participant_1 == UUID(user1_id), ChatRoom.participant_2 == UUID(user2_id)),
                and_(ChatRoom.participant_1 == UUID(user2_id), ChatRoom.participant_2 == UUID(user1_id)),
            ),
        )
        .first()
    )
    if not room:
        room = ChatRoom(
            trip_id=UUID(trip_id),
            participant_1=UUID(user1_id),
            participant_2=UUID(user2_id),
        )
        db.add(room)
        db.commit()
        db.refresh(room)

    return {
        "id": str(room.id),
        "trip_id": str(room.trip_id),
        "participant_1": str(room.participant_1),
        "participant_2": str(room.participant_2),
        "created_at": room.created_at.isoformat(),
    }


@router.get("/room/{room_id}/messages")
async def get_messages(
    room_id: str,
    limit: int = Query(default=50, le=200),
    before: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Récupère les messages d'une room (pagination par curseur)."""
    query = db.query(Message).filter(Message.room_id == UUID(room_id))
    if before:
        query = query.filter(Message.created_at < datetime.fromisoformat(before))
    messages = query.order_by(desc(Message.created_at)).limit(limit).all()
    return {"data": [_serialize_message(m) for m in reversed(messages)]}


@router.post("/room/{room_id}/messages", status_code=201)
async def send_message(room_id: str, req: MessageCreate, db: Session = Depends(get_db)):
    """Envoie un message dans une room."""
    room = db.query(ChatRoom).filter(ChatRoom.id == UUID(room_id)).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room non trouvée")

    msg = Message(
        room_id=UUID(room_id),
        sender_id=req.sender_id,
        content=req.content,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    serialized = _serialize_message(msg)
    publish_event(f"chat:{room_id}", {"type": "new_message", "message": serialized})
    return serialized


@router.put("/room/{room_id}/read/{user_id}")
async def mark_messages_read(room_id: str, user_id: str, db: Session = Depends(get_db)):
    """Marque tous les messages non lus d'une room comme lus (sauf ceux de l'user)."""
    db.query(Message).filter(
        Message.room_id == UUID(room_id),
        Message.sender_id != UUID(user_id),
        Message.is_read == False,
    ).update({"is_read": True})
    db.commit()
    return {"message": "Messages marqués comme lus"}


@router.get("/user/{user_id}/rooms")
async def get_user_rooms(user_id: str, db: Session = Depends(get_db)):
    """Récupère toutes les rooms d'un utilisateur avec le dernier message."""
    rooms = (
        db.query(ChatRoom)
        .filter(
            or_(
                ChatRoom.participant_1 == UUID(user_id),
                ChatRoom.participant_2 == UUID(user_id),
            )
        )
        .all()
    )

    result = []
    for room in rooms:
        last_msg = (
            db.query(Message)
            .filter(Message.room_id == room.id)
            .order_by(desc(Message.created_at))
            .first()
        )
        unread = (
            db.query(Message)
            .filter(
                Message.room_id == room.id,
                Message.sender_id != UUID(user_id),
                Message.is_read == False,
            )
            .count()
        )
        result.append({
            "id": str(room.id),
            "trip_id": str(room.trip_id),
            "participant_1": str(room.participant_1),
            "participant_2": str(room.participant_2),
            "last_message": _serialize_message(last_msg) if last_msg else None,
            "unread_count": unread,
            "created_at": room.created_at.isoformat(),
        })

    return {"data": result}
