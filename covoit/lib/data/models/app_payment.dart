class AppPaymentInitiation {
  final String paymentId;
  final String providerPaymentId;
  final String status;
  final String providerStatus;
  final String message;
  final int amount;
  final String paymentMethod;
  final String paymentType;
  final String phoneNumber;
  final String? channelName;
  final String? channelUssd;
  final String? operatorCode;
  final String? paymentUrl;

  const AppPaymentInitiation({
    required this.paymentId,
    required this.providerPaymentId,
    required this.status,
    required this.providerStatus,
    required this.message,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    required this.phoneNumber,
    this.channelName,
    this.channelUssd,
    this.operatorCode,
    this.paymentUrl,
  });

  factory AppPaymentInitiation.fromApi(Map<String, dynamic> json) {
    return AppPaymentInitiation(
      paymentId: json['payment_id']?.toString() ?? '',
      providerPaymentId: json['provider_payment_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      providerStatus: json['provider_status']?.toString() ?? 'PENDING',
      message: json['message']?.toString() ?? '',
      amount: _asInt(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? 'mtn',
      paymentType: json['payment_type']?.toString() ?? 'booking',
      phoneNumber: json['phone_number']?.toString() ?? '',
      channelName: json['channel_name']?.toString(),
      channelUssd: json['channel_ussd']?.toString(),
      operatorCode: json['operator_code']?.toString(),
      paymentUrl: json['payment_url']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AppPaymentVerification {
  final String paymentId;
  final String status;
  final String providerStatus;
  final bool isFinal;
  final String message;
  final String? providerPaymentId;
  final String? operatorTransactionId;

  const AppPaymentVerification({
    required this.paymentId,
    required this.status,
    required this.providerStatus,
    required this.isFinal,
    required this.message,
    this.providerPaymentId,
    this.operatorTransactionId,
  });

  bool get isSuccess => status == 'success';

  bool get isFailure => status == 'failed' || status == 'cancelled';

  factory AppPaymentVerification.fromApi(Map<String, dynamic> json) {
    return AppPaymentVerification(
      paymentId: json['payment_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      providerStatus: json['provider_status']?.toString() ?? 'PENDING',
      isFinal: json['is_final'] == true,
      message: json['message']?.toString() ?? '',
      providerPaymentId: json['provider_payment_id']?.toString(),
      operatorTransactionId: json['operator_transaction_id']?.toString(),
    );
  }
}
