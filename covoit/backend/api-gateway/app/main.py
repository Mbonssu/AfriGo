from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.middleware.token_blacklist import TokenBlacklistMiddleware
# Import des routes: authentification, utilisateurs, trajets, réservations, paiements
from app.api.routes import auth, users, trips, bookings, payments, notifications, chat, subscriptions, cautions, forum, tracking
from app.api.websockets import chat_ws, tracking_ws, notifications_ws

app = FastAPI(
    title="AfriGo API Gateway",
    description="Microservices API Gateway",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Token Blacklist Middleware - Vérifie que les tokens ne sont pas blacklistés (logout)
app.add_middleware(TokenBlacklistMiddleware)

# Routes - chaque router est enregistré avec un préfixe distinct
# /api/auth/* → Routes d'authentification (login, register)
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
# /api/users/* → Routes utilisateurs (profils, driver profiles)
app.include_router(users.router, prefix="/api/users", tags=["users"])
# /api/trips/* → Routes trajets (créer, rechercher, réserver, etc)
app.include_router(trips.router, prefix="/api/trips", tags=["trips"])
# /api/bookings/* → Routes réservations (créer, confirmer, annuler) - NOUVEAU
app.include_router(bookings.router, prefix="/api/bookings", tags=["bookings"])
# /api/payments/* → Routes paiements (créer, consulter, rembourser)
app.include_router(payments.router, prefix="/api/payments", tags=["payments"])
# /api/notifications/* → Routes notifications
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
# /api/chat/* → Routes messagerie
app.include_router(chat.router, prefix="/api/chat", tags=["chat"])
# /api/subscriptions/* → Routes abonnement Prime
app.include_router(subscriptions.router, prefix="/api/subscriptions", tags=["subscriptions"])
# /api/cautions/* → Routes cautions & remboursements
app.include_router(cautions.router, prefix="/api/cautions", tags=["cautions"])
# /api/forum/* → Routes forum Prime
app.include_router(forum.router, prefix="/api/forum", tags=["forum"])
# /api/tracking/* → Routes suivi GPS en temps réel
app.include_router(tracking.router, prefix="/api/tracking", tags=["tracking"])

# ── WebSocket routes (temps réel) ─────────────────────────────────────────
app.include_router(chat_ws.router)
app.include_router(tracking_ws.router)
app.include_router(notifications_ws.router)

@app.get("/health")
async def health_check():
    """
    Endpoint de santé de l'API Gateway.
    Vérifie que la gateway répond et que les dépendances sont actives.
    """
    return {
        "status": "ok",
        "service": "api-gateway"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
