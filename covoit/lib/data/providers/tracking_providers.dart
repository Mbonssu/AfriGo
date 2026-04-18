import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../repositories/tracking_repository.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TrackingRepository(client);
});

final tripTrackingProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, tripId) {
  final repo = ref.watch(trackingRepositoryProvider);
  return repo.getTracking(tripId);
});
