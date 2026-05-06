import os
import uuid
from pathlib import Path
from typing import Optional
from fastapi import UploadFile
import aiofiles
import logging

logger = logging.getLogger(__name__)

class FileService:
    """Service for handling file uploads"""
    
    def __init__(self, upload_dir: str = "/app/uploads"):
        self.upload_dir = Path(upload_dir)
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        self.profile_dir = self.upload_dir / "profiles"
        self.kyc_dir = self.upload_dir / "kyc"
        self.vehicles_dir = self.upload_dir / "vehicles"
        
        self.profile_dir.mkdir(exist_ok=True)
        self.kyc_dir.mkdir(exist_ok=True)
        self.vehicles_dir.mkdir(exist_ok=True)
    
    async def save_profile_photo(self, user_id: str, file: UploadFile) -> str:
        """Save profile photo and return URL"""
        return await self._save_file(file, self.profile_dir, f"profile_{user_id}")
    
    async def save_cni_photo(self, user_id: str, file: UploadFile) -> str:
        """Save CNI/Passport photo and return URL"""
        return await self._save_file(file, self.kyc_dir, f"cni_{user_id}")
    
    async def save_selfie(self, user_id: str, file: UploadFile) -> str:
        """Save selfie photo and return URL"""
        return await self._save_file(file, self.kyc_dir, f"selfie_{user_id}")
    
    async def save_license_photo(self, user_id: str, file: UploadFile) -> str:
        """Save driver license photo and return URL"""
        return await self._save_file(file, self.kyc_dir, f"license_{user_id}")
    
    async def save_registration_card(self, user_id: str, file: UploadFile) -> str:
        """Save vehicle registration card photo and return URL"""
        return await self._save_file(file, self.kyc_dir, f"registration_{user_id}")
    
    async def save_vehicle_photo(self, vehicle_id: str, file: UploadFile, position: int = 0) -> str:
        """Save vehicle photo and return URL"""
        return await self._save_file(file, self.vehicles_dir, f"vehicle_{vehicle_id}_{position}")
    
    async def _save_file(self, file: UploadFile, directory: Path, prefix: str) -> str:
        """Internal method to save file"""
        try:
            # Get file extension
            ext = Path(file.filename).suffix if file.filename else ".jpg"
            if not ext:
                ext = ".jpg"
            
            # Generate unique filename
            filename = f"{prefix}_{uuid.uuid4().hex[:8]}{ext}"
            file_path = directory / filename
            
            # Save file
            async with aiofiles.open(file_path, 'wb') as out_file:
                content = await file.read()
                await out_file.write(content)
            
            # Return relative URL
            relative_path = file_path.relative_to(self.upload_dir)
            url = f"/uploads/{relative_path}"
            
            logger.info(f"File saved: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Error saving file: {e}")
            raise
    
    def delete_file(self, url: str) -> bool:
        """Delete file by URL"""
        try:
            if not url.startswith("/uploads/"):
                return False
            
            # Extract path from URL
            relative_path = url.replace("/uploads/", "")
            file_path = self.upload_dir / relative_path
            
            if file_path.exists():
                file_path.unlink()
                logger.info(f"File deleted: {url}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error deleting file: {e}")
            return False


# Singleton instance
file_service = FileService()
