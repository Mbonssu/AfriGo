import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class TrackingRepository {
  final ApiClient _client;

  TrackingRepository(this._client);

  Future<Map<String, dynamic>> getTracking(String tripId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.tripTracking(tripId),
    );
  }

  Future<Map<String, dynamic>> startTracking({
    required String tripId,
    required String driverId,
    required List<Map<String, dynamic>> steps,
  }) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.startTracking,
      data: {
        'trip_id': tripId,
        'driver_id': driverId,
        'steps': steps,
      },
    );
  }

  Future<Map<String, dynamic>> updatePosition({
    required String tripId,
    required double lat,
    required double lng,
    required double progress,
    String? currentStep,
  }) async {
    return await _client.put<Map<String, dynamic>>(
      ApiEndpoints.updateTrackingPosition(tripId),
      data: {
        'lat': lat,
        'lng': lng,
        'progress': progress,
        if (currentStep != null) 'current_step': currentStep,
      },
    );
  }

  Future<void> completeTracking(String tripId) async {
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.completeTracking(tripId),
    );
  }
}
