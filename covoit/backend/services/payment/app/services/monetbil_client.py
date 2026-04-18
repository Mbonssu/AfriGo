from __future__ import annotations

from typing import Any, Dict

import httpx

from app.core.config import settings


class MonetbilClientError(Exception):
    pass


class MonetbilClient:
    """Petit client HTTP dédié à l'API Collections v1 de Monetbil."""

    @staticmethod
    def place_payment(payload: Dict[str, Any]) -> Dict[str, Any]:
        return MonetbilClient._post("/placePayment", payload)

    @staticmethod
    def check_payment(payment_id: str) -> Dict[str, Any]:
        return MonetbilClient._post("/checkPayment", {"paymentId": payment_id})

    @staticmethod
    def _post(path: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        if not settings.MONETBIL_SERVICE_KEY:
            raise MonetbilClientError(
                "MONETBIL_SERVICE_KEY n'est pas configurée dans le payment-service."
            )

        url = f"{settings.MONETBIL_API_BASE_URL.rstrip('/')}{path}"
        try:
            with httpx.Client(timeout=30.0) as client:
                response = client.post(url, json=payload)
        except httpx.RequestError as exc:
            raise MonetbilClientError(f"Impossible de joindre Monetbil: {exc}") from exc

        try:
            data = response.json()
        except ValueError as exc:
            raise MonetbilClientError(
                f"Reponse Monetbil invalide ({response.status_code}): {response.text}"
            ) from exc

        if response.status_code >= 400:
            detail = data.get("message") or data.get("detail") or response.text
            raise MonetbilClientError(
                f"Erreur Monetbil ({response.status_code}): {detail}"
            )

        return data
