class AppDriverProfile {
  final String userId;
  final String fullName;
  final bool isPrime;
  final double rating;
  final int ratingCount;
  final int totalTrips;
  final String? phone;
  final String? profilePictureUrl;

  const AppDriverProfile({
    required this.userId,
    required this.fullName,
    required this.isPrime,
    required this.rating,
    required this.ratingCount,
    required this.totalTrips,
    this.phone,
    this.profilePictureUrl,
  });

  factory AppDriverProfile.fromApi({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? driverData,
  }) {
    final firstName = (userData?['first_name'] ?? '').toString().trim();
    final lastName = (userData?['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

    return AppDriverProfile(
      userId: userId,
      fullName: fullName.isNotEmpty ? fullName : 'Chauffeur ${_shortId(userId)}',
      isPrime: _asBool(driverData?['is_prime']),
      rating: _asDouble(driverData?['rating'] ?? userData?['rating']),
      ratingCount: _asInt(userData?['total_reviews']),
      totalTrips: _asInt(driverData?['total_trips']),
      phone: userData?['phone']?.toString(),
      profilePictureUrl: userData?['profile_picture_url']?.toString(),
    );
  }

  factory AppDriverProfile.fallback(String userId) {
    return AppDriverProfile(
      userId: userId,
      fullName: 'Chauffeur ${_shortId(userId)}',
      isPrime: false,
      rating: 0,
      ratingCount: 0,
      totalTrips: 0,
      profilePictureUrl: null,
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _shortId(String value) {
    if (value.length <= 6) return value;
    return value.substring(value.length - 6);
  }

  String get initials {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
