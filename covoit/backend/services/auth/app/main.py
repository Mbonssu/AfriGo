from fastapi import FastAPI
from app.core.config import settings
from app.api.routes import auth, logout
from app.db.session import create_tables
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Covoit Auth Service",
    description="Authentication service",
    version="1.0.0"
)

@app.on_event("startup")
async def startup():
    logger.info("Starting Auth Service")
    create_tables()

@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down Auth Service")

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(logout.router, prefix="/auth", tags=["auth"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "auth-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
