from datetime import datetime, timedelta
from typing import Optional, Tuple
from sqlalchemy import or_
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
import bcrypt
from jose import JWTError, jwt
from app.core.config import settings
from app.models.user import User, UserRole
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
import logging

logger = logging.getLogger(__name__)


class AuthService:
    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    
    @staticmethod
    def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode = {"sub": str(user_id), "exp": expire}
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def create_refresh_token(user_id: str) -> str:
        expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode = {"sub": str(user_id), "type": "refresh", "exp": expire}
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Optional[str]:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id: str = payload.get("sub")
            return user_id
        except JWTError:
            return None
    
    @staticmethod
    def register(db: Session, request: RegisterRequest) -> Tuple[User, str, str]:
        logger.info(f"Starting registration for email: {request.email}, role: {request.role}")
        
        # Check if user exists
        existing_user = db.query(User).filter(
            or_(User.email == request.email, User.phone == request.phone)
        ).first()
        if existing_user:
            if existing_user.email == request.email:
                logger.error(f"User already exists with email: {request.email}")
                raise ValueError("User already exists")
            logger.error(f"Phone already exists: {request.phone}")
            raise ValueError("Phone already exists")
        
        # Create user
        try:
            role_value = UserRole(request.role).value
            logger.info(f"Converting role {request.role} to {role_value}")
        except ValueError as e:
            logger.error(f"Invalid role: {request.role}, error: {e}")
            raise ValueError(f"Invalid role: {request.role}")
            
        user = User(
            email=request.email,
            phone=request.phone,
            password_hash=AuthService.hash_password(request.password),
            role=role_value
        )
        logger.info(f"Created user object: {user.email}")
        
        db.add(user)
        try:
            db.commit()
            logger.info(f"User committed to database: {user.email}")
        except IntegrityError as e:
            db.rollback()
            logger.error(f"Database integrity error: {e}")
            raise ValueError("Email or phone already exists")
        except Exception as e:
            db.rollback()
            logger.error(f"Database commit error: {e}")
            raise ValueError("Database error during registration")
            
        db.refresh(user)
        
        # Generate tokens
        access_token = AuthService.create_access_token(str(user.id))
        refresh_token = AuthService.create_refresh_token(str(user.id))
        
        logger.info(f"User registered successfully: {user.email}")
        return user, access_token, refresh_token
    
    @staticmethod
    def login(db: Session, request: LoginRequest) -> Tuple[User, str, str]:
        # Find user
        user = db.query(User).filter(User.email == request.email).first()
        if not user or not AuthService.verify_password(request.password, user.password_hash):
            raise ValueError("Invalid credentials")
        
        if not user.is_active:
            raise ValueError("User is inactive")
        
        # Generate tokens
        access_token = AuthService.create_access_token(str(user.id))
        refresh_token = AuthService.create_refresh_token(str(user.id))
        
        logger.info(f"User logged in: {user.email}")
        return user, access_token, refresh_token
