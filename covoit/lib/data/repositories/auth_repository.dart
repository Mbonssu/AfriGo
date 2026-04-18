import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../models/auth_session.dart';

class AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  const AuthRepository(this._client, this._tokenStorage);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final session = AuthSession.fromApi(response);
    await saveSession(session);
    return session;
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'phone': phone,
        'role': role == 'chauffeur' ? 'driver' : 'passenger',
      },
    );

    final session = AuthSession.fromApi(response);
    await saveSession(session);
    return session;
  }

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _tokenStorage.saveAccessToken(session.accessToken),
      if (session.refreshToken != null && session.refreshToken!.isNotEmpty)
        _tokenStorage.saveRefreshToken(session.refreshToken!),
      _tokenStorage.saveUserId(session.userId),
      _tokenStorage.saveUserRole(session.appRole),
    ]);
  }

  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
  }) async {
    final payload = <String, dynamic>{
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
    };

    if (payload.isEmpty) return;

    await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.userById(userId),
      data: payload,
    );
  }

  /// Logout : blacklist le token côté backend puis nettoie le stockage local.
  Future<void> logout() async {
    try {
      await _client.post<dynamic>(ApiEndpoints.logout, data: {});
    } catch (_) {
      // Même si le backend est injoignable, on nettoie le local
    }
    await _tokenStorage.clearAll();
  }
}
