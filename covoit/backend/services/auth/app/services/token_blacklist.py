# Import de Redis pour la cache et la blacklist
import redis
from datetime import datetime, timedelta
import json
from typing import Optional

# Import de la configuration
from app.core.config import settings

# ============================================================================
# CONNEXION À REDIS
# ============================================================================

# Créer une connexion Redis pour stocker la blacklist des tokens
# Redis est un cache en mémoire ultra-rapide, parfait pour les blacklists
redis_client = redis.Redis(
    # Hôte du serveur Redis
    host=settings.REDIS_HOST,
    # Port du serveur Redis
    port=settings.REDIS_PORT,
    # Numéro de la base de données
    db=0,
    # Décoder les réponses en UTF-8
    decode_responses=True,
)

# ============================================================================
# SERVICE DE BLACKLIST
# ============================================================================

class TokenBlacklistService:
    """
    Service pour gérer la blacklist des tokens JWT.
    
    Quand un utilisateur se déconnecte (logout), son token est ajouté à la blacklist.
    Les tokens blacklistés sont refusés à la prochaine requête.
    
    Utilise Redis pour la performance:
    - Stockage rapide en mémoire
    - Expiration automatique des clés
    - Pas de dépendance à une base de données
    """
    
    # Préfixe pour les clés Redis (evite les collisions)
    BLACKLIST_PREFIX = "token_blacklist:"
    
    @staticmethod
    def add_token_to_blacklist(token: str, expires_in: int) -> bool:
        """
        Ajoute un token JWT à la blacklist.
        
        Paramètres:
            token: Le token JWT complet à blacklister
            expires_in: Nombre de secondes avant l'expiration du token
        
        Retour:
            bool: True si succès, False sinon
        
        Exemple:
            >>> from datetime import datetime, timedelta
            >>> token_expiration = 900  # 15 minutes
            >>> TokenBlacklistService.add_token_to_blacklist(token, token_expiration)
            True
        """
        
        try:
            # Créer une clé unique pour ce token
            # Format: token_blacklist:{token_hash}
            blacklist_key = f"{TokenBlacklistService.BLACKLIST_PREFIX}{token}"
            
            # Stocker le token avec:
            # - Valeur: timestamp du blacklist (pour l'audit)
            # - Expiration: même durée que le token original
            redis_client.setex(
                # Clé unique
                blacklist_key,
                # Durée de vie en secondes (match l'expiration du token)
                expires_in,
                # Valeur: timestamp ISO du blacklist
                datetime.utcnow().isoformat()
            )
            
            # Log pour l'audit
            print(f"[BLACKLIST] Token ajouté à la blacklist (expire dans {expires_in}s)")
            
            # Retourner le succès
            return True
        
        except Exception as e:
            # Gérer les erreurs Redis
            print(f"[ERROR] Erreur lors de l'ajout à la blacklist: {str(e)}")
            return False
    
    @staticmethod
    def is_token_blacklisted(token: str) -> bool:
        """
        Vérifie si un token JWT est blacklisté.
        
        Paramètres:
            token: Le token JWT à vérifier
        
        Retour:
            bool: True si blacklisté, False sinon
        
        Exemple:
            >>> if TokenBlacklistService.is_token_blacklisted(token):
            ...     raise UnauthorizedError("Token a été blacklisté (logout)")
        """
        
        try:
            # Créer la clé Redis
            blacklist_key = f"{TokenBlacklistService.BLACKLIST_PREFIX}{token}"
            
            # Vérifier si la clé existe dans Redis
            # Si elle existe → token est blacklisté
            # Si elle n'existe pas → token est valide (ou expiré)
            result = redis_client.exists(blacklist_key)
            
            # result = 0 → n'existe pas (valide)
            # result = 1 → existe (blacklisté)
            is_blacklisted = result == 1
            
            return is_blacklisted
        
        except Exception as e:
            # En cas d'erreur Redis, on refuse le token par sécurité
            print(f"[ERROR] Erreur lors de la vérification blacklist: {str(e)}")
            return True  # Par défaut: refuser le token
    
    @staticmethod
    def remove_from_blacklist(token: str) -> bool:
        """
        Supprime un token de la blacklist (rare, mais utile pour les tests).
        
        Paramètres:
            token: Le token JWT à retirer
        
        Retour:
            bool: True si supprimé, False sinon
        """
        
        try:
            blacklist_key = f"{TokenBlacklistService.BLACKLIST_PREFIX}{token}"
            result = redis_client.delete(blacklist_key)
            return result == 1
        except Exception as e:
            print(f"[ERROR] Erreur lors de la suppression: {str(e)}")
            return False
    
    @staticmethod
    def clear_blacklist() -> bool:
        """
        Vide toute la blacklist (utile pour les tests ou le nettoyage).
        
        Retour:
            bool: True si succès
        """
        
        try:
            # Récupérer toutes les clés avec le préfixe
            pattern = f"{TokenBlacklistService.BLACKLIST_PREFIX}*"
            # Utiliser SCAN pour éviter de bloquer Redis sur un grand nombre de clés
            cursor = 0
            deleted_count = 0
            
            while True:
                cursor, keys = redis_client.scan(cursor, match=pattern, count=100)
                for key in keys:
                    redis_client.delete(key)
                    deleted_count += 1
                
                if cursor == 0:
                    break
            
            print(f"[BLACKLIST] {deleted_count} tokens supprimés de la blacklist")
            return True
        
        except Exception as e:
            print(f"[ERROR] Erreur lors du vidage: {str(e)}")
            return False
    
    @staticmethod
    def get_blacklist_stats() -> dict:
        """
        Récupère des statistiques sur la blacklist.
        
        Retour:
            dict: Statistiques (nombre de tokens, taille mémoire, etc.)
        """
        
        try:
            # Obtenir la taille de la blacklist
            pattern = f"{TokenBlacklistService.BLACKLIST_PREFIX}*"
            cursor = 0
            count = 0
            
            while True:
                cursor, keys = redis_client.scan(cursor, match=pattern, count=100)
                count += len(keys)
                
                if cursor == 0:
                    break
            
            # Obtenir la taille en mémoire
            info = redis_client.info()
            used_memory = info.get("used_memory_human", "N/A")
            
            return {
                "blacklisted_tokens": count,
                "redis_memory": used_memory,
                "status": "healthy" if count < 10000 else "warning"
            }
        
        except Exception as e:
            print(f"[ERROR] Erreur lors des statistiques: {str(e)}")
            return {"error": str(e)}
