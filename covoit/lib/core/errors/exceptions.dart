/// Exceptions levées dans la couche Data (datasources, repositories impl).
/// Elles ne remontent JAMAIS jusqu'aux screens — elles sont converties
/// en [Failure] au niveau du repository.
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// Le serveur a répondu avec une erreur HTTP (4xx, 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// Erreur réseau : pas de connexion, timeout, DNS.
final class NetworkException extends AppException {
  const NetworkException(super.message) : super(statusCode: null);
}

/// Le token JWT est absent ou expiré et le refresh a échoué.
final class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Session expirée. Veuillez vous reconnecter.', statusCode: 401);
}

/// Le JSON reçu ne correspond pas au modèle attendu.
final class ParseException extends AppException {
  const ParseException(super.message) : super(statusCode: null);
}

/// Erreur de cache / stockage local.
final class CacheException extends AppException {
  const CacheException(super.message) : super(statusCode: null);
}
