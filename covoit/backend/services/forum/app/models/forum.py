from sqlalchemy import Column, String, DateTime, Integer, Boolean, Text, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from datetime import datetime

Base = declarative_base()


class PostCategory(str, enum.Enum):
    discussion = "discussion"
    announcement = "announcement"
    tip = "tip"


class ForumPost(Base):
    __tablename__ = "forum_posts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    author_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    author_name = Column(String(100), nullable=False)
    author_avatar = Column(String(10), nullable=True)
    category = Column(SAEnum(PostCategory), nullable=False, default=PostCategory.discussion)
    content = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    is_platform = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    comments = relationship("ForumComment", back_populates="post", order_by="ForumComment.created_at")
    likes = relationship("ForumLike", back_populates="post")


class ForumComment(Base):
    __tablename__ = "forum_comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("forum_posts.id"), nullable=False, index=True)
    author_id = Column(UUID(as_uuid=True), nullable=False)
    author_name = Column(String(100), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    post = relationship("ForumPost", back_populates="comments")


class ForumLike(Base):
    __tablename__ = "forum_likes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("forum_posts.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
