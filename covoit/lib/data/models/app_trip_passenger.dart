import 'app_user_profile.dart';

/// Représente un passager (booking) vu par le conducteur.
class AppTripPassenger {
  final String bookingId;
  final String passengerId;
  final int numberOfSeats;
  final int totalPrice;
  final String status; // pending, confirmed, cancelled, completed, no_show
  final String? pickupLocation;
  final AppUserProfile? profile;

  // Boarding / vérification embarquement
  final bool isBoarded;
  final String? boardedAt;
  final String? boardingMethod;

  const AppTripPassenger({
    required this.bookingId,
    required this.passengerId,
    required this.numberOfSeats,
    required this.totalPrice,
    required this.status,
    this.pickupLocation,
    this.profile,
    this.isBoarded = false,
    this.boardedAt,
    this.boardingMethod,
  });

  String get displayName => profile?.fullName ?? 'Passager';

  String get initials => profile?.initials ?? '?';

  String get phone => profile?.phone ?? '';
  
  String? get photoUrl => profile?.profilePictureUrl;

  bool get isPaid => status == 'confirmed' || status == 'completed';
}
