import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/token_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// Client HTTP central de l'application.
///
/// Toutes les requêtes réseau passent par ici.
/// Fournit des méthodes typées (get, post, put, patch, delete) qui
/// convertissent automatiquement les erreurs en [AppException].
///
/// À consommer via Riverpod (voir providers/api_client_provider.dart).
class ApiClient {
  final Dio _dio;

  ApiClient._(this._dio);

  /// Factory recommandée — configure Dio avec tous les interceptors.
  factory ApiClient.create({required TokenStorage tokenStorage}) {
    final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none,
      ),
    );

    final dio = Dio(
      BaseOptions(
        // Point d'entrée unique : le gateway.
        // Tous les /api/auth/*, /api/trips/*, etc. sont routés par le gateway
        // vers les microservices internes (auth:8001, trip:8003, etc.).
        baseUrl: ApiEndpoints.gatewayUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Name': 'AfriGo',
        },
      ),
    );

    // Ordre important : Auth → Error → Logger (du plus spécifique au plus général)
    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, tokenStorage: tokenStorage, logger: logger),
      ErrorInterceptor(logger),
      // Logger uniquement en mode debug
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: false,
        ),
    ]);

    return ApiClient._(dio);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Méthodes HTTP publiques
  // ═══════════════════════════════════════════════════════════════════════════

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _safeRequest<T>(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
    return response;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() => _dio.put<T>(
          path,
          data: data,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() => _dio.patch<T>(
          path,
          data: data,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  Future<void> delete(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _safeRequest<dynamic>(() => _dio.delete(
          path,
          data: data,
          options: options,
          cancelToken: cancelToken,
        ));
  }

  /// Upload multipart (documents, photos de profil)
  Future<T> uploadFile<T>(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() => _dio.post<T>(
          path,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Wrapper de sécurité interne
  // ═══════════════════════════════════════════════════════════════════════════

  Future<T> _safeRequest<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      // L'ErrorInterceptor a déjà converti en AppException
      if (e.error is AppException) throw e.error as AppException;
      // Fallback au cas où l'interceptor aurait laissé passer
      throw ServerException(e.message ?? 'Erreur réseau inattendue.');
    }
  }
}
