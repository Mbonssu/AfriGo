import 'package:equatable/equatable.dart';

/// Valeurs d'échec typées, retournées par les repositories vers la Presentation.
/// La Presentation ne voit jamais d'exceptions — seulement des Failure.
///
/// Elles sont immutables et comparables (via Equatable) pour faciliter les tests.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Erreur provenant du serveur (4xx, 5xx).
final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Pas de connexion internet ou timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// L'utilisateur n'est pas / plus authentifié.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expirée. Veuillez vous reconnecter.']);
}

/// Erreur de parsing JSON.
final class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Erreur de stockage local.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Erreur de validation côté client (champ manquant, format invalide).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
