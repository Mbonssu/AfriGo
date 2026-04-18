import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/app_driver_profile.dart';
import '../models/app_user_profile.dart';

class UserRepository {
  final ApiClient _client;
  AppUserProfile? _cachedProfile;
  String? _cachedUserId;

  UserRepository(this._client);

  Future<AppUserProfile> getProfile(String userId) async {
    if (_cachedProfile != null && _cachedUserId == userId) {
      return _cachedProfile!;
    }
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userProfile(userId),
    );
    final profile = AppUserProfile.fromApi(response);
    _cachedProfile = profile;
    _cachedUserId = userId;
    return profile;
  }

  Future<AppDriverProfile> getDriverProfile(String userId) async {
    Map<String, dynamic>? userData;
    Map<String, dynamic>? driverData;
    try {
      userData = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.userProfile(userId),
      );
    } catch (_) {}
    try {
      driverData = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.driverPublicProfile(userId),
      );
    } catch (_) {}
    if (userData == null && driverData == null) {
      return AppDriverProfile.fallback(userId);
    }
    return AppDriverProfile.fromApi(
      userId: userId,
      userData: userData,
      driverData: driverData,
    );
  }

  void invalidateCache() {
    _cachedProfile = null;
    _cachedUserId = null;
  }
}
