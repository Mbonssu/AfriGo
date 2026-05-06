class AppUserProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? bio;
  final String? profilePictureUrl;
  final double rating;
  final int totalReviews;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String kycStatus; // none, pending, verified, rejected
  final String? cniType;
  final String? cniNumber;
  final double? faceMatchScore;

  const AppUserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.bio,
    this.profilePictureUrl,
    required this.rating,
    required this.totalReviews,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.kycStatus = 'none',
    this.cniType,
    this.cniNumber,
    this.faceMatchScore,
  });

  factory AppUserProfile.fromApi(Map<String, dynamic> json) {
    return AppUserProfile(
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString().trim(),
      lastName: (json['last_name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString(),
      bio: json['bio']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      rating: _asDouble(json['rating']),
      totalReviews: _asInt(json['total_reviews']),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      kycStatus: (json['kyc_status'] ?? 'none').toString(),
      cniType: json['cni_type']?.toString(),
      cniNumber: json['cni_number']?.toString(),
      faceMatchScore: json['face_match_score'] != null ? _asDouble(json['face_match_score']) : null,
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Utilisateur';
  }

  String get initials {
    // Si firstName et lastName sont vides, utiliser l'email ou le téléphone
    if (firstName.isEmpty && lastName.isEmpty) {
      // Essayer d'utiliser la première lettre du téléphone ou '?'
      if (phone.isNotEmpty) {
        return phone[0].toUpperCase();
      }
      return '?';
    }
    
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
}
