from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.db.session import get_db
from app.models.forum import ForumPost, ForumComment, ForumLike, PostCategory
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


class PostCreate(BaseModel):
    author_id: UUID
    author_name: str = Field(..., min_length=2, max_length=60)
    author_avatar: Optional[str] = None
    category: PostCategory = PostCategory.DISCUSSION
    content: str = Field(..., min_length=10, max_length=4000)

    @field_validator("author_name")
    @classmethod
    def normalize_author_name(cls, value: str) -> str:
        return value.strip()

    @field_validator("content")
    @classmethod
    def normalize_content(cls, value: str) -> str:
        return value.strip()


class CommentCreate(BaseModel):
    author_id: UUID
    author_name: str = Field(..., min_length=2, max_length=60)
    content: str = Field(..., min_length=1, max_length=1000)

    @field_validator("author_name")
    @classmethod
    def normalize_comment_author_name(cls, value: str) -> str:
        return value.strip()

    @field_validator("content")
    @classmethod
    def normalize_comment_content(cls, value: str) -> str:
        return value.strip()


def _serialize_post(p: ForumPost) -> dict:
    return {
        "id": str(p.id),
        "author_id": str(p.author_id),
        "author_name": p.author_name,
        "author_avatar": p.author_avatar,
        "category": p.category.value,
        "content": p.content,
        "likes_count": p.likes_count,
        "comments_count": p.comments_count,
        "is_platform": p.is_platform,
        "created_at": p.created_at.isoformat(),
    }


def _serialize_comment(c: ForumComment) -> dict:
    return {
        "id": str(c.id),
        "post_id": str(c.post_id),
        "author_id": str(c.author_id),
        "author_name": c.author_name,
        "content": c.content,
        "created_at": c.created_at.isoformat(),
    }


@router.get("/posts")
async def get_posts(
    category: Optional[str] = None,
    limit: int = Query(default=50, le=100),
    db: Session = Depends(get_db),
):
    """Récupère les posts du forum, optionnellement filtrés par catégorie."""
    query = db.query(ForumPost)
    if category:
        query = query.filter(ForumPost.category == PostCategory(category))
    posts = query.order_by(desc(ForumPost.created_at)).limit(limit).all()
    return {"data": [_serialize_post(p) for p in posts]}


@router.post("/posts", status_code=201)
async def create_post(req: PostCreate, db: Session = Depends(get_db)):
    """Crée un nouveau post dans le forum."""
    post = ForumPost(
        author_id=req.author_id,
        author_name=req.author_name,
        author_avatar=req.author_avatar,
        category=req.category,
        content=req.content,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return _serialize_post(post)


@router.get("/posts/{post_id}")
async def get_post(post_id: str, db: Session = Depends(get_db)):
    """Récupère un post avec ses commentaires."""
    post = db.query(ForumPost).filter(ForumPost.id == UUID(post_id)).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")

    comments = (
        db.query(ForumComment)
        .filter(ForumComment.post_id == post.id)
        .order_by(ForumComment.created_at)
        .all()
    )
    result = _serialize_post(post)
    result["comments"] = [_serialize_comment(c) for c in comments]
    return result


@router.post("/posts/{post_id}/comments", status_code=201)
async def add_comment(post_id: str, req: CommentCreate, db: Session = Depends(get_db)):
    """Ajoute un commentaire à un post."""
    post = db.query(ForumPost).filter(ForumPost.id == UUID(post_id)).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")

    comment = ForumComment(
        post_id=UUID(post_id),
        author_id=req.author_id,
        author_name=req.author_name,
        content=req.content,
    )
    db.add(comment)
    post.comments_count += 1
    db.commit()
    db.refresh(comment)
    return _serialize_comment(comment)


@router.post("/posts/{post_id}/like")
async def toggle_like(post_id: str, user_id: str, db: Session = Depends(get_db)):
    """Toggle like sur un post."""
    post = db.query(ForumPost).filter(ForumPost.id == UUID(post_id)).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")

    existing = (
        db.query(ForumLike)
        .filter(ForumLike.post_id == UUID(post_id), ForumLike.user_id == UUID(user_id))
        .first()
    )
    if existing:
        db.delete(existing)
        post.likes_count = max(0, post.likes_count - 1)
        db.commit()
        return {"liked": False, "likes_count": post.likes_count}
    else:
        like = ForumLike(post_id=UUID(post_id), user_id=UUID(user_id))
        db.add(like)
        post.likes_count += 1
        db.commit()
        return {"liked": True, "likes_count": post.likes_count}


@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, user_id: str, db: Session = Depends(get_db)):
    """Supprime un post (auteur uniquement)."""
    post = db.query(ForumPost).filter(ForumPost.id == UUID(post_id)).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post non trouvé")
    if str(post.author_id) != user_id:
        raise HTTPException(status_code=403, detail="Non autorisé")

    db.query(ForumComment).filter(ForumComment.post_id == post.id).delete()
    db.query(ForumLike).filter(ForumLike.post_id == post.id).delete()
    db.delete(post)
    db.commit()
    return {"message": "Post supprimé"}
