import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper autour de [FlutterSecureStorage] pour persister le JWT.
/// Le token est stocké dans le Keychain (iOS) ou Keystore (Android).
///
/// Usage : injecter via Riverpod (voir auth_provider.dart).
class TokenStorage {
  final FlutterSecureStorage _storage;

  const TokenStorage(this._storage);

  // ── Access Token ──────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.keyAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.keyAccessToken);

  Future<void> deleteAccessToken() =>
      _storage.delete(key: AppConstants.keyAccessToken);

  // ── Refresh Token ─────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: AppConstants.keyRefreshToken);

  // ── User metadata ─────────────────────────────────────────────────────────

  Future<void> saveUserRole(String role) =>
      _storage.write(key: AppConstants.keyUserRole, value: role);

  Future<String?> getUserRole() =>
      _storage.read(key: AppConstants.keyUserRole);

  Future<void> saveUserId(String id) =>
      _storage.write(key: AppConstants.keyUserId, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.keyUserId);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Supprime tous les tokens (utilisé au logout ou si refresh échoue).
  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      _storage.delete(key: AppConstants.keyUserRole),
      _storage.delete(key: AppConstants.keyUserId),
    ]);
  }

  /// Vérifie si un access token est présent (ne vérifie pas l'expiration).
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
