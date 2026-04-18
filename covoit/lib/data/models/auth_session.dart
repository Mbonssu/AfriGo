class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String email;
  final String phone;
  final String backendRole;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.phone,
    required this.backendRole,
  });

  factory AuthSession.fromApi(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? const {});

    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      userId: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      backendRole: user['role']?.toString() ?? 'passenger',
    );
  }

  bool get isDriver => backendRole == 'driver';

  String get appRole => isDriver ? 'chauffeur' : 'passager';
}
