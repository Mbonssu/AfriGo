from fastapi import FastAPI
from app.core.config import settings
from app.api.routes import forum
from app.db.session import create_tables
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Covoit Forum Service",
    description="Forum exclusif Prime",
    version="1.0.0"
)

@app.on_event("startup")
async def startup():
    logger.info("Starting Forum Service")
    create_tables()

@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down Forum Service")

app.include_router(forum.router, prefix="/forum", tags=["forum"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "forum-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
