import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class CautionRepository {
  final ApiClient _client;

  CautionRepository(this._client);

  Future<Map<String, dynamic>> getUserCautions(String userId, {String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userCautions(userId),
      queryParameters: params.isNotEmpty ? params : null,
    );
  }

  Future<Map<String, dynamic>> getSummary(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      ApiEndpoints.cautionSummary(userId),
    );
  }
}
