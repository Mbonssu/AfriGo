import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../utils/token_storage.dart';

// ─── flutter_secure_storage ────────────────────────────────────────────────

/// Options Android : chiffrement avec EncryptedSharedPreferences
const _androidOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

/// Options iOS : accessible uniquement quand l'app est au premier plan
const _iosOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
);

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
});

// ─── TokenStorage ──────────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return TokenStorage(storage);
});

// ─── ApiClient ─────────────────────────────────────────────────────────────

/// Singleton Dio configuré avec tous les interceptors.
/// À utiliser dans tous les datasources de l'application.
///
/// Exemple d'usage dans un datasource :
/// ```dart
/// final client = ref.watch(apiClientProvider);
/// final data = await client.get<Map<String,dynamic>>('/api/v1/trips');
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient.create(tokenStorage: tokenStorage);
});
