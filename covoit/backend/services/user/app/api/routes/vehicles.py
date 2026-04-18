from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List
from app.schemas.user import VehicleResponse, VehicleCreate, VehicleUpdate, VehiclePhotoResponse
from app.services.user_service import VehicleService
from app.db.session import get_db
import logging
import os
import uuid as uuid_mod
import shutil

logger = logging.getLogger(__name__)

UPLOAD_ROOT = os.getenv("UPLOAD_ROOT", "/app/uploads")
UPLOAD_DIR = os.path.join(UPLOAD_ROOT, "vehicles")

router = APIRouter()


@router.get("/{user_id}/vehicles", response_model=List[VehicleResponse])
async def list_vehicles(user_id: str, db: Session = Depends(get_db)):
    try:
        vehicles = VehicleService.list_vehicles(db, UUID(user_id))
        return vehicles
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")


@router.post("/{user_id}/vehicles", response_model=VehicleResponse, status_code=201)
async def create_vehicle(user_id: str, data: VehicleCreate, db: Session = Depends(get_db)):
    try:
        vehicle = VehicleService.create_vehicle(db, UUID(user_id), data)
        return vehicle
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    except Exception as e:
        logger.error(f"Error creating vehicle: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/{user_id}/vehicles/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle(user_id: str, vehicle_id: str, db: Session = Depends(get_db)):
    try:
        vehicle = VehicleService.get_vehicle(db, UUID(vehicle_id))
        if not vehicle or str(vehicle.user_id) != user_id:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        return vehicle
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ID")


@router.patch("/{user_id}/vehicles/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(user_id: str, vehicle_id: str, data: VehicleUpdate, db: Session = Depends(get_db)):
    try:
        vehicle = VehicleService.get_vehicle(db, UUID(vehicle_id))
        if not vehicle or str(vehicle.user_id) != user_id:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        updated = VehicleService.update_vehicle(db, UUID(vehicle_id), data)
        return updated
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ID")
    except Exception as e:
        logger.error(f"Error updating vehicle: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{user_id}/vehicles/{vehicle_id}", status_code=204)
async def delete_vehicle(user_id: str, vehicle_id: str, db: Session = Depends(get_db)):
    try:
        vehicle = VehicleService.get_vehicle(db, UUID(vehicle_id))
        if not vehicle or str(vehicle.user_id) != user_id:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        VehicleService.delete_vehicle(db, UUID(vehicle_id))
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ID")


@router.post("/{user_id}/vehicles/{vehicle_id}/photos", response_model=VehiclePhotoResponse, status_code=201)
async def upload_vehicle_photo(
    user_id: str,
    vehicle_id: str,
    position: int = 0,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    try:
        vehicle = VehicleService.get_vehicle(db, UUID(vehicle_id))
        if not vehicle or str(vehicle.user_id) != user_id:
            raise HTTPException(status_code=404, detail="Vehicle not found")

        # Validate file type
        if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
            raise HTTPException(status_code=400, detail="Only JPEG, PNG and WebP images are allowed")

        # Limit file size (5 MB)
        contents = await file.read()
        if len(contents) > 5 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="File too large (max 5 MB)")

        os.makedirs(UPLOAD_DIR, exist_ok=True)

        ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
        filename = f"{uuid_mod.uuid4()}.{ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        with open(filepath, "wb") as f:
            f.write(contents)

        photo_url = f"/uploads/vehicles/{filename}"
        photo = VehicleService.add_photo(db, UUID(vehicle_id), photo_url, position)
        if not photo:
            raise HTTPException(status_code=500, detail="Failed to save photo record")

        result = {
            "id": str(photo.id),
            "photo_url": photo.photo_url,
            "position": photo.position,
        }
        return result

    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ID")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading photo: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{user_id}/vehicles/{vehicle_id}/photos/{photo_id}", status_code=204)
async def delete_vehicle_photo(user_id: str, vehicle_id: str, photo_id: str, db: Session = Depends(get_db)):
    try:
        vehicle = VehicleService.get_vehicle(db, UUID(vehicle_id))
        if not vehicle or str(vehicle.user_id) != user_id:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        deleted = VehicleService.delete_photo(db, UUID(photo_id))
        if not deleted:
            raise HTTPException(status_code=404, detail="Photo not found")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid ID")
