import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/app_booking_trip.dart';
import '../models/app_driver_profile.dart';
import '../models/app_trip.dart';
import '../models/app_trip_passenger.dart';
import '../models/app_user_profile.dart';

class DriverTripsUnavailableException implements Exception {
  final String message;

  const DriverTripsUnavailableException(this.message);

  @override
  String toString() => message;
}

class JourneyRepository {
  final ApiClient _client;
  final Map<String, Future<AppDriverProfile>> _driverCache = {};

  JourneyRepository(this._client);

  Future<List<Map<String, dynamic>>> getPopularRoutes() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.popularRoutes,
    );
    final data = response['data'] as List?;
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<AppTrip>> searchTrips({
    required String from,
    required String to,
    DateTime? departureDate,
    int passengerCount = 1,
    String sortBy = 'departure_time',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.searchTrips,
      queryParameters: {
        if (from.isNotEmpty) 'from_city': from,
        if (to.isNotEmpty) 'to_city': to,
        if (departureDate != null) 'departure_date': _dateOnly(departureDate),
        'passenger_count': passengerCount,
        'sort_by': sortBy,
      },
    );

    final trips = _asMapList(response['trips']);
    return Future.wait(trips.map(_hydrateTrip));
  }

  Future<List<AppBookingTrip>> getPassengerTrips(String passengerId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.passengerBookings(passengerId),
    );
    final bookings = _asMapList(response['data']);
    return Future.wait(bookings.map(_hydrateBookingTrip));
  }

  Future<void> cancelBooking(String bookingId) {
    return _client.post<dynamic>(
      ApiEndpoints.cancelBooking(bookingId),
      data: {'reason': 'Annulation depuis l’application mobile'},
    );
  }

  Future<String> createBooking({
    required String tripId,
    required String passengerId,
    required int numberOfSeats,
    required int totalPrice,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.bookings,
      data: {
        'trip_id': tripId,
        'passenger_id': passengerId,
        'number_of_seats': numberOfSeats,
        'total_price': totalPrice,
      },
    );

    final bookingId = response['id']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      throw const ParseException('Impossible de lire la réservation créée.');
    }
    return bookingId;
  }

  Future<void> confirmBooking({
    required String bookingId,
    required String paymentId,
  }) {
    return _client.post<dynamic>(
      ApiEndpoints.confirmBooking(bookingId),
      data: {'payment_id': paymentId},
    );
  }

  Future<void> acceptBooking(String bookingId) {
    return _client.post<dynamic>(
      ApiEndpoints.acceptBooking(bookingId),
    );
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) {
    return _client.post<dynamic>(
      ApiEndpoints.rejectBooking(bookingId),
      data: {'reason': reason ?? 'Refusé par le conducteur'},
    );
  }

  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? comment,
    List<String> tags = const [],
  }) {
    return _client.post<dynamic>(
      ApiEndpoints.rateBooking(bookingId),
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
  }

  Future<List<AppTrip>> getDriverTrips() async {
    try {
      final response = await _client.get<dynamic>(ApiEndpoints.myDriverTrips);
      if (response is List) {
        return Future.wait(
          response
              .whereType<Map>()
              .map((item) => _hydrateTrip(Map<String, dynamic>.from(item))),
        );
      }
      if (response is Map<String, dynamic>) {
        final trips = _asMapList(response['data'] ?? response['trips']);
        return Future.wait(trips.map(_hydrateTrip));
      }
      return const [];
    } on AppException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        throw const DriverTripsUnavailableException(
          'Endpoint trajets chauffeur indisponible.',
        );
      }
      rethrow;
    }
  }

  Future<List<AppTrip>> getDriverTripsById(String driverId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.driverTrips(driverId),
    );
    final trips = _asMapList(response['data']);
    return Future.wait(trips.map(_hydrateTrip));
  }

  Future<AppTrip> createTrip({
    required String driverId,
    required String departureCity,
    required String arrivalCity,
    required DateTime departureTime,
    required int totalSeats,
    required double pricePerSeat,
    required String vehicleModel,
    required String vehiclePlate,
    String? vehicleId,
    bool isPrime = false,
    List<String> comfortOptions = const [],
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiEndpoints.trips}/',
      data: {
        'driver_id': driverId,
        'departure_city': departureCity,
        'arrival_city': arrivalCity,
        'departure_time': departureTime.toIso8601String(),
        'total_seats': totalSeats,
        'price_per_seat': pricePerSeat,
        'vehicle_model': vehicleModel,
        'vehicle_plate': vehiclePlate,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        'is_prime': isPrime,
        if (comfortOptions.isNotEmpty) 'comfort_options': comfortOptions,
      },
    );
    return _hydrateTrip(response);
  }

  Future<List<AppTripPassenger>> getTripBookings(String tripId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.tripBookings(tripId),
    );
    final bookings = _asMapList(response['data']);
    final passengers = <AppTripPassenger>[];
    for (final b in bookings) {
      final passengerId = b['passenger_id']?.toString() ?? '';
      AppUserProfile? profile;
      try {
        final userData = await _safeGetMap(ApiEndpoints.userById(passengerId));
        if (userData != null) {
          profile = AppUserProfile.fromApi(userData);
        }
      } catch (_) {}
      passengers.add(AppTripPassenger(
        bookingId: b['id']?.toString() ?? '',
        passengerId: passengerId,
        numberOfSeats: _asIntStatic(b['number_of_seats']),
        totalPrice: _asIntStatic(b['total_price']),
        status: b['status']?.toString() ?? 'pending',
        pickupLocation: b['pickup_location']?.toString(),
        profile: profile,
      ));
    }
    return passengers;
  }

  Future<void> deleteTrip(String tripId) {
    return _client.delete(ApiEndpoints.tripById(tripId));
  }


  Future<AppBookingTrip> _hydrateBookingTrip(
      Map<String, dynamic> bookingJson) async {
    final tripId = bookingJson['trip_id']?.toString() ?? '';
    final tripJson =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.tripById(tripId));
    final trip = await _hydrateTrip(tripJson);

    return AppBookingTrip(
      bookingId: bookingJson['id']?.toString() ?? '',
      bookingStatus: bookingJson['status']?.toString() ?? 'pending',
      numberOfSeats: AppBookingTrip.asInt(bookingJson['number_of_seats']),
      totalPrice: AppBookingTrip.asInt(bookingJson['total_price']),
      trip: trip,
    );
  }

  Future<AppTrip> _hydrateTrip(Map<String, dynamic> tripJson) async {
    final driverId = tripJson['driver_id']?.toString() ?? '';
    final driver = await _getDriverProfile(driverId);
    return AppTrip.fromApi(tripJson, driver: driver);
  }

  Future<AppDriverProfile> _getDriverProfile(String userId) {
    return _driverCache.putIfAbsent(userId, () async {
      final userData = await _safeGetMap(ApiEndpoints.userById(userId));
      final driverData =
          await _safeGetMap(ApiEndpoints.driverPublicProfile(userId));

      if (userData == null && driverData == null) {
        return AppDriverProfile.fallback(userId);
      }

      return AppDriverProfile.fromApi(
        userId: userId,
        userData: userData,
        driverData: driverData,
      );
    });
  }

  Future<Map<String, dynamic>?> _safeGetMap(String path) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(path);
      return response;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static int _asIntStatic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ══════════════════════════════════════════════════════════════════════
  // BOARDING / VÉRIFICATION EMBARQUEMENT
  // ══════════════════════════════════════════════════════════════════════

  /// Récupère le code PIN d'embarquement (côté passager).
  Future<Map<String, dynamic>> getBoardingCode(String bookingId) async {
    return _client.get<Map<String, dynamic>>(
      ApiEndpoints.boardingCode(bookingId),
    );
  }

  /// Vérifie l'embarquement d'un passager (côté chauffeur).
  Future<Map<String, dynamic>> verifyBoarding({
    required String bookingId,
    required String code,
    String method = 'pin',
  }) async {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.verifyBoarding(bookingId),
      data: {'code': code, 'method': method},
    );
  }

  /// Récupère le statut d'embarquement de tous les passagers d'un trajet.
  Future<Map<String, dynamic>> getTripBoardingStatus(String tripId) async {
    return _client.get<Map<String, dynamic>>(
      ApiEndpoints.tripBoardingStatus(tripId),
    );
  }
}
