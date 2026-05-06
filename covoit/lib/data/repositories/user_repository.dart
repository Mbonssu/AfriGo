import 'dart:io';
import 'package:dio/dio.dart';
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
      print('📦 UserRepository: Returning cached profile for $userId');
      print('📦 Profile picture URL: ${_cachedProfile!.profilePictureUrl}');
      return _cachedProfile!;
    }
    print('🌐 UserRepository: Fetching profile from API for $userId');
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userProfile(userId),
    );
    print('📥 UserRepository: Response received: $response');
    final profile = AppUserProfile.fromApi(response);
    print('✅ UserRepository: Profile parsed, picture URL: ${profile.profilePictureUrl}');
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

  Future<Map<String, dynamic>> updateProfileWithPhoto({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    File? photo,
  }) async {
    final formData = FormData();
    
    if (firstName != null) {
      formData.files.add(MapEntry('first_name', MultipartFile.fromString(firstName)));
    }
    if (lastName != null) {
      formData.files.add(MapEntry('last_name', MultipartFile.fromString(lastName)));
    }
    if (phone != null) {
      formData.files.add(MapEntry('phone', MultipartFile.fromString(phone)));
    }
    if (photo != null) {
      final fileName = photo.path.split('/').last;
      formData.files.add(MapEntry(
        'photo',
        await MultipartFile.fromFile(photo.path, filename: fileName),
      ));
    }

    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.updateProfile(userId),
      data: formData,
    );

    invalidateCache();
    return response;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String userId,
    required File photo,
  }) async {
    final fileName = photo.path.split('/').last;
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
    });

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.uploadProfilePhoto(userId),
      data: formData,
    );

    invalidateCache();
    return response;
  }

  Future<Map<String, dynamic>> uploadKYCDocuments({
    required String userId,
    required File cniPhoto,
    required File selfie,
    File? licensePhoto,
    File? registrationCard,
  }) async {
    final formData = FormData();

    // CNI photo (required)
    formData.files.add(MapEntry(
      'cni_photo',
      await MultipartFile.fromFile(
        cniPhoto.path,
        filename: cniPhoto.path.split('/').last,
      ),
    ));

    // Selfie (required)
    formData.files.add(MapEntry(
      'selfie',
      await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.path.split('/').last,
      ),
    ));

    // License photo (optional)
    if (licensePhoto != null) {
      formData.files.add(MapEntry(
        'license_photo',
        await MultipartFile.fromFile(
          licensePhoto.path,
          filename: licensePhoto.path.split('/').last,
        ),
      ));
    }

    // Registration card (optional)
    if (registrationCard != null) {
      formData.files.add(MapEntry(
        'registration_card',
        await MultipartFile.fromFile(
          registrationCard.path,
          filename: registrationCard.path.split('/').last,
        ),
      ));
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.verifyKYC(userId),
      data: formData,
    );

    invalidateCache();
    return response;
  }

  void invalidateCache() {
    print('🗑️ UserRepository: Cache invalidated');
    _cachedProfile = null;
    _cachedUserId = null;
  }
}
