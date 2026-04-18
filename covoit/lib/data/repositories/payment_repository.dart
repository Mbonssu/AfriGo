import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/app_payment.dart';

class PaymentRepository {
  final ApiClient _client;

  PaymentRepository(this._client);

  Future<AppPaymentInitiation> initiatePayment({
    required String userId,
    String? bookingId,
    required int amount,
    required String paymentMethod,
    required String paymentType,
    required String phoneNumber,
    String? description,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.initPayment,
      data: {
        'user_id': userId,
        if (bookingId != null) 'booking_id': bookingId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_type': paymentType,
        'phone_number': phoneNumber,
        if (description != null) 'description': description,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
      },
    );

    return AppPaymentInitiation.fromApi(response);
  }

  Future<AppPaymentVerification> verifyPayment(String paymentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.verifyPayment,
      data: {'payment_id': paymentId},
    );

    return AppPaymentVerification.fromApi(response);
  }
}
