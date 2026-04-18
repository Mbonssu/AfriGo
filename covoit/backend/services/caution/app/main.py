from fastapi import FastAPI
from app.core.config import settings
from app.api.routes import cautions
from app.db.session import create_tables
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Covoit Caution Service",
    description="Service de gestion des cautions",
    version="1.0.0"
)

@app.on_event("startup")
async def startup():
    logger.info("Starting Caution Service")
    create_tables()

@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down Caution Service")

app.include_router(cautions.router, prefix="/cautions", tags=["cautions"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "caution-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
