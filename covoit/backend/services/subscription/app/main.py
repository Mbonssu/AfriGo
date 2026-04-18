from fastapi import FastAPI
from app.core.config import settings
from app.api.routes import subscriptions
from app.db.session import create_tables, seed_plans
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Covoit Subscription Service",
    description="Service d'abonnement Prime",
    version="1.0.0"
)

@app.on_event("startup")
async def startup():
    logger.info("Starting Subscription Service")
    create_tables()
    seed_plans()

@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down Subscription Service")

app.include_router(subscriptions.router, prefix="/subscriptions", tags=["subscriptions"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "subscription-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
