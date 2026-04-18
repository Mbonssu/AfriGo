import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  Future<Map<String, dynamic>> getUserNotifications(String userId, {int limit = 50}) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userNotifications(userId),
      queryParameters: {'limit': limit},
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.markNotificationRead(notificationId),
    );
  }

  Future<void> markAllAsRead(String userId) async {
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.markAllNotificationsRead(userId),
    );
  }
}
