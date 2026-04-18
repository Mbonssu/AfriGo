import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../models/app_driver_profile.dart';
import '../models/app_user_profile.dart';
import '../repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserRepository(client);
});

final userProfileProvider =
    FutureProvider.autoDispose.family<AppUserProfile, String>((ref, userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile(userId);
});

final driverProfileProvider =
    FutureProvider.autoDispose.family<AppDriverProfile, String>((ref, userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getDriverProfile(userId);
});
