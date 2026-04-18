import 'app_trip.dart';

class AppBookingTrip {
  final String bookingId;
  final String bookingStatus;
  final int numberOfSeats;
  final int totalPrice;
  final AppTrip trip;

  const AppBookingTrip({
    required this.bookingId,
    required this.bookingStatus,
    required this.numberOfSeats,
    required this.totalPrice,
    required this.trip,
  });

  String get effectiveStatus {
    if (bookingStatus == 'cancelled' || trip.status == 'cancelled') {
      return 'cancelled';
    }
    if (trip.status == 'ongoing') {
      return 'ongoing';
    }
    if (bookingStatus == 'completed' || trip.status == 'completed') {
      return 'completed';
    }
    if (bookingStatus == 'confirmed') {
      return 'confirmed';
    }
    return bookingStatus;
  }

  static int asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
