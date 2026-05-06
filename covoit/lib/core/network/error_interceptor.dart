import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/exceptions.dart';

/// Convertit chaque [DioException] en une [AppException] typée.
/// Cet interceptor garantit que la couche Data ne laisse jamais
/// remonter de DioException brute vers le Domain ou la Presentation.
class ErrorInterceptor extends Interceptor {
  final Logger _logger;

  const ErrorInterceptor(this._logger);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Si l'erreur a déjà été convertie (ex: par AuthInterceptor), on passe
    if (err.error is AppException) {
      handler.next(err);
      return;
    }

    final appException = _convertError(err);
    _logger.e(
      'ErrorInterceptor: ${appException.runtimeType}',
      error: appException.message,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: appException,
        type: err.type,
      ),
    );
  }

  AppException _convertError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Délai d\'attente dépassé. Vérifiez votre connexion.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(err.response, err.requestOptions.path);

      case DioExceptionType.cancel:
        return const NetworkException('Requête annulée.');

      case DioExceptionType.badCertificate:
        return const NetworkException('Erreur de certificat SSL.');

      default:
        return ServerException(
          err.message ?? 'Une erreur inattendue s\'est produite.',
        );
    }
  }

  AppException _handleHttpError(Response? response, String requestPath) {
    if (response == null) {
      return const ServerException('Pas de réponse du serveur.');
    }

    final statusCode = response.statusCode ?? 0;
    // Cherche le message d'erreur dans le body de la réponse FastAPI
    // FastAPI retourne typiquement : {"detail": "message"} ou {"message": "..."}
    final dynamic data = response.data;
    final message = _extractMessage(data, statusCode);

    switch (statusCode) {
      case 400:
        return ServerException(message, statusCode: 400);
      case 401:
        if (requestPath == '/api/auth/login' || requestPath == '/api/auth/register') {
          return ServerException(message, statusCode: 401);
        }
        return const UnauthorizedException();
      case 403:
        return ServerException(message, statusCode: 403);
      case 404:
        return ServerException(message, statusCode: 404);
      case 409:
        return const ServerException('Conflit de données.', statusCode: 409);
      case 422:
        // FastAPI Unprocessable Entity — validation error
        return ServerException(_extractValidationError(data), statusCode: 422);
      case 429:
        return const ServerException(
          'Trop de requêtes. Réessayez dans un moment.',
          statusCode: 429,
        );
      case >= 500:
        return ServerException(
          'Erreur serveur ($statusCode). Réessayez plus tard.',
          statusCode: statusCode,
        );
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }

  String _extractMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      // Format FastAPI standard
      if (data['detail'] is String) return data['detail'] as String;
      
      // Format imbriqué : {"detail": {"detail": "message"}}
      if (data['detail'] is Map<String, dynamic>) {
        final nestedDetail = data['detail'] as Map<String, dynamic>;
        if (nestedDetail['detail'] is String) {
          return nestedDetail['detail'] as String;
        }
      }
      
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
    }
    return 'Erreur $statusCode.';
  }

  /// FastAPI retourne les erreurs de validation sous la forme :
  /// {"detail": [{"loc": [...], "msg": "...", "type": "..."}]}
  String _extractValidationError(dynamic data) {
    if (data is Map<String, dynamic> && data['detail'] is List) {
      final errors = (data['detail'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => e['msg']?.toString() ?? '')
          .where((msg) => msg.isNotEmpty)
          .take(3)
          .join(', ');
      if (errors.isNotEmpty) return 'Données invalides : $errors';
    }
    return 'Données invalides.';
  }
}
