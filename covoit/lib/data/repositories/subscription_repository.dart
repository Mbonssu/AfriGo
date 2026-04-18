import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository(this._client);

  Future<Map<String, dynamic>> getPlans() async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionPlans,
    );
  }

  Future<Map<String, dynamic>> subscribe({required String userId, required String planType, String? paymentReference}) async {
    return await _client.post<Map<String, dynamic>>(
      ApiEndpoints.subscribe,
      data: {
        'user_id': userId,
        'plan_type': planType,
        'payment_reference': paymentReference,
      },
    );
  }

  Future<Map<String, dynamic>> getUserSubscription(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userSubscription(userId),
    );
  }

  Future<Map<String, dynamic>> getHistory(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionHistory(userId),
    );
  }

  Future<void> cancel(String userId) async {
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.cancelSubscription(userId),
    );
  }
}
