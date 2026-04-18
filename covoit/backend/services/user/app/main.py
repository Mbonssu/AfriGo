from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.api.routes import users, vehicles
from app.db.session import create_tables
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

UPLOAD_ROOT = os.getenv("UPLOAD_ROOT", "/app/uploads")

# Create upload directory before mounting StaticFiles
os.makedirs(os.path.join(UPLOAD_ROOT, "vehicles"), exist_ok=True)

app = FastAPI(
    title="Covoit User Service",
    description="User profile service",
    version="1.0.0"
)

@app.on_event("startup")
async def startup():
    logger.info("Starting User Service")
    create_tables()

@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down User Service")

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(vehicles.router, prefix="/users", tags=["vehicles"])
app.mount("/uploads", StaticFiles(directory=UPLOAD_ROOT), name="uploads")

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "user-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
