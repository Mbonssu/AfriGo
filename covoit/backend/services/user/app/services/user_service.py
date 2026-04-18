from sqlalchemy.orm import Session
from app.models.user_profile import UserProfile, DriverProfile, Vehicle, VehiclePhoto
from app.schemas.user import UserProfileUpdate, DriverProfileUpdate, VehicleCreate, VehicleUpdate
from uuid import UUID
import logging

logger = logging.getLogger(__name__)

class UserService:
    @staticmethod
    def create_profile(db: Session, user_id: UUID, phone: str = '') -> UserProfile:
        """Create user profile for newly registered user"""
        user_profile = UserProfile(user_id=user_id, phone=phone)
        db.add(user_profile)
        db.commit()
        db.refresh(user_profile)
        logger.info(f"User profile created for {user_id}")
        return user_profile
    
    @staticmethod
    def get_profile(db: Session, user_id: UUID) -> UserProfile:
        """Get user profile, auto-create if missing"""
        profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
        if not profile:
            profile = UserService.create_profile(db, user_id)
        return profile
    
    @staticmethod
    def update_profile(db: Session, user_id: UUID, data: UserProfileUpdate) -> UserProfile:
        """Update user profile"""
        profile = UserService.get_profile(db, user_id)
        if not profile:
            phone = data.phone or '' if hasattr(data, 'phone') else ''
            profile = UserService.create_profile(db, user_id, phone=phone)
        
        for key, value in data.dict(exclude_unset=True).items():
            setattr(profile, key, value)
        
        db.commit()
        db.refresh(profile)
        logger.info(f"User profile updated for {user_id}")
        return profile

class DriverService:
    @staticmethod
    def create_driver_profile(db: Session, user_id: UUID, data: DriverProfileUpdate) -> DriverProfile:
        """Create driver profile"""
        driver_profile = DriverProfile(user_id=user_id, **data.dict())
        db.add(driver_profile)
        db.commit()
        db.refresh(driver_profile)
        logger.info(f"Driver profile created for {user_id}")
        return driver_profile
    
    @staticmethod
    def get_driver_profile(db: Session, user_id: UUID) -> DriverProfile:
        """Get driver profile, auto-create if missing"""
        profile = db.query(DriverProfile).filter(DriverProfile.user_id == user_id).first()
        if not profile:
            profile = DriverProfile(user_id=user_id, license_number='', vehicle_model='', vehicle_plate='')
            db.add(profile)
            db.commit()
            db.refresh(profile)
            logger.info(f"Driver profile auto-created for {user_id}")
        return profile
    
    @staticmethod
    def update_driver_profile(db: Session, user_id: UUID, data: DriverProfileUpdate) -> DriverProfile:
        """Update driver profile"""
        driver_profile = DriverService.get_driver_profile(db, user_id)
        if not driver_profile:
            driver_profile = DriverService.create_driver_profile(db, user_id, data)
        else:
            for key, value in data.dict(exclude_unset=True).items():
                setattr(driver_profile, key, value)
            db.commit()
            db.refresh(driver_profile)
        
        logger.info(f"Driver profile updated for {user_id}")
        return driver_profile


class VehicleService:
    @staticmethod
    def list_vehicles(db: Session, user_id: UUID) -> list[Vehicle]:
        return db.query(Vehicle).filter(Vehicle.user_id == user_id).order_by(Vehicle.created_at.desc()).all()

    @staticmethod
    def get_vehicle(db: Session, vehicle_id: UUID) -> Vehicle | None:
        return db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()

    @staticmethod
    def create_vehicle(db: Session, user_id: UUID, data: VehicleCreate) -> Vehicle:
        vehicle = Vehicle(user_id=user_id, **data.model_dump())
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        logger.info(f"Vehicle created for {user_id}: {vehicle.brand} {vehicle.model}")
        return vehicle

    @staticmethod
    def update_vehicle(db: Session, vehicle_id: UUID, data: VehicleUpdate) -> Vehicle | None:
        vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
        if not vehicle:
            return None
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(vehicle, key, value)
        db.commit()
        db.refresh(vehicle)
        logger.info(f"Vehicle updated: {vehicle_id}")
        return vehicle

    @staticmethod
    def delete_vehicle(db: Session, vehicle_id: UUID) -> bool:
        vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
        if not vehicle:
            return False
        db.delete(vehicle)
        db.commit()
        logger.info(f"Vehicle deleted: {vehicle_id}")
        return True

    @staticmethod
    def add_photo(db: Session, vehicle_id: UUID, photo_url: str, position: int = 0) -> VehiclePhoto | None:
        vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
        if not vehicle:
            return None
        photo = VehiclePhoto(vehicle_id=vehicle_id, photo_url=photo_url, position=position)
        db.add(photo)
        db.commit()
        db.refresh(photo)
        logger.info(f"Photo added to vehicle {vehicle_id}")
        return photo

    @staticmethod
    def delete_photo(db: Session, photo_id: UUID) -> bool:
        photo = db.query(VehiclePhoto).filter(VehiclePhoto.id == photo_id).first()
        if not photo:
            return False
        db.delete(photo)
        db.commit()
        logger.info(f"Photo deleted: {photo_id}")
        return True
