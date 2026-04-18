import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../utils/token_storage.dart';

/// Injecte le JWT sur chaque requête et gère le refresh silencieux.
///
/// Flux :
///   1. `onRequest`  → ajoute `Authorization: Bearer <token>`
///   2. `onError`    → si 401 → tente le refresh → retry la requête originale
///   3. Si refresh échoue → [UnauthorizedException] → l'app déconnecte l'user
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Logger _logger;

  /// Flag pour éviter les boucles infinies de refresh
  bool _isRefreshing = false;

  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required Logger logger,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _logger = logger;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Routes publiques définies dans ApiEndpoints.publicRoutes :
    // login, register, refreshToken, trips (GET), searchTrips, healthCheck
    final isPublicRoute = ApiEndpoints.publicRoutes.contains(options.path);
    if (!isPublicRoute) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    // Éviter le retry sur les endpoints d'auth eux-mêmes
    final path = err.requestOptions.path;
    if (path == ApiEndpoints.login ||
        path == ApiEndpoints.refreshToken ||
        path == ApiEndpoints.register) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      _logger.d('AuthInterceptor: token expiré, tentative de refresh...');
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        _logger.d('AuthInterceptor: refresh OK, retry de la requête originale');
        final retryResponse = await _retryRequest(err.requestOptions);
        handler.resolve(retryResponse);
      } else {
        _logger.w('AuthInterceptor: refresh échoué → déconnexion');
        await _tokenStorage.clearAll();
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } catch (e) {
      await _tokenStorage.clearAll();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
          type: DioExceptionType.badResponse,
        ),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Privé ─────────────────────────────────────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Requête directe sans passer par les interceptors (évite boucle infinie)
      final freshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await freshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

      if (newAccessToken == null) return false;

      await _tokenStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _tokenStorage.saveRefreshToken(newRefreshToken);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final newToken = await _tokenStorage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newToken',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // publicRoutes est défini dans ApiEndpoints.publicRoutes — source unique de vérité.
}
