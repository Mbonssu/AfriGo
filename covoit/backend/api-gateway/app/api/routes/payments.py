from fastapi import APIRouter, HTTPException, Request, status
import httpx
from urllib.parse import parse_qsl

from app.core.config import settings


router = APIRouter(tags=["Payments"])


def _proxy_error_detail(response: httpx.Response, fallback: str):
    try:
        data = response.json()
    except ValueError:
        return response.text or fallback

    if isinstance(data, dict):
        return data.get("detail", fallback)
    return data


async def _request_payment_service(
    method: str,
    path: str,
    *,
    json: dict | None = None,
    params: dict | None = None,
):
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(
                method,
                f"{settings.PAYMENT_SERVICE_URL}{path}",
                json=json,
                params=params,
            )
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Payment Service indisponible",
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail=_proxy_error_detail(response, "Erreur du Payment Service"),
        )

    return response.json()


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    summary="Créer un nouveau paiement",
)
async def create_payment(request: dict):
    return await _request_payment_service("POST", "/payments", json=request)


@router.post(
    "/initiate",
    status_code=status.HTTP_201_CREATED,
    summary="Initialiser un paiement Monetbil",
)
async def initiate_payment(request: dict):
    return await _request_payment_service("POST", "/payments/initiate", json=request)


@router.post(
    "/verify",
    status_code=status.HTTP_200_OK,
    summary="Vérifier le statut d'un paiement Monetbil",
)
async def verify_payment(request: dict):
    return await _request_payment_service("POST", "/payments/verify", json=request)


@router.get(
    "/history",
    status_code=status.HTTP_200_OK,
    summary="Historique des paiements d'un utilisateur",
)
async def payment_history(user_id: str, limit: int = 20, offset: int = 0):
    return await _request_payment_service(
        "GET",
        "/payments/history",
        params={"user_id": user_id, "limit": limit, "offset": offset},
    )


@router.api_route(
    "/notify/monetbil",
    methods=["GET", "POST"],
    status_code=status.HTTP_200_OK,
    summary="Recevoir une notification Monetbil",
)
async def monetbil_notification(request: Request):
    if request.method == "GET":
        payload = dict(request.query_params)
    else:
        try:
            payload = await request.json()
        except Exception:
            raw_body = (await request.body()).decode()
            payload = dict(parse_qsl(raw_body))

    return await _request_payment_service(
        request.method,
        "/payments/notify/monetbil",
        json=payload if request.method == "POST" else None,
        params=payload if request.method == "GET" else None,
    )


@router.get(
    "/user/{user_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les paiements d'un utilisateur",
)
async def get_user_payments(user_id: str, limit: int = 20, offset: int = 0):
    return await _request_payment_service(
        "GET",
        f"/payments/user/{user_id}",
        params={"limit": limit, "offset": offset},
    )


@router.post(
    "/search",
    status_code=status.HTTP_200_OK,
    summary="Rechercher les paiements",
)
async def search_payments(request: dict):
    return await _request_payment_service("POST", "/payments/search", json=request)


@router.get(
    "/{payment_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer un paiement par son ID",
)
async def get_payment(payment_id: str):
    return await _request_payment_service("GET", f"/payments/{payment_id}")


@router.put(
    "/{payment_id}/status",
    status_code=status.HTTP_200_OK,
    summary="Mettre à jour le statut d'un paiement",
)
async def update_payment_status(payment_id: str, request: dict):
    return await _request_payment_service(
        "PUT",
        f"/payments/{payment_id}/status",
        json=request,
    )


@router.post(
    "/{payment_id}/cancel",
    status_code=status.HTTP_200_OK,
    summary="Annuler un paiement",
)
async def cancel_payment(payment_id: str):
    return await _request_payment_service("POST", f"/payments/{payment_id}/cancel")


@router.post(
    "/{payment_id}/refund",
    status_code=status.HTTP_200_OK,
    summary="Rembourser un paiement",
)
async def refund_payment(payment_id: str, request: dict):
    return await _request_payment_service(
        "POST",
        f"/payments/{payment_id}/refund",
        json=request,
    )


@router.get(
    "/stats/user/{user_id}",
    status_code=status.HTTP_200_OK,
    summary="Récupérer les statistiques d'un utilisateur",
)
async def get_payment_stats(user_id: str):
    return await _request_payment_service("GET", f"/payments/stats/user/{user_id}")
