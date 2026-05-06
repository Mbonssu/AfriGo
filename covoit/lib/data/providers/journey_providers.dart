import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../models/app_booking_trip.dart';
import '../models/app_trip.dart';
import '../models/app_trip_passenger.dart';
import '../repositories/journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return JourneyRepository(client);
});

final currentUserIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  return storage.getUserId();
});

class TripSearchQuery extends Equatable {
  final String from;
  final String to;
  final DateTime? departureDate;
  final int passengerCount;
  final String sortBy;

  const TripSearchQuery({
    required this.from,
    required this.to,
    this.departureDate,
    this.passengerCount = 1,
    this.sortBy = 'departure_time',
  });

  @override
  List<Object?> get props => [from, to, departureDate, passengerCount, sortBy];
}

final searchTripsProvider =
    FutureProvider.autoDispose.family<List<AppTrip>, TripSearchQuery>((ref, query) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.searchTrips(
    from: query.from,
    to: query.to,
    departureDate: query.departureDate,
    passengerCount: query.passengerCount,
    sortBy: query.sortBy,
  );
});

final passengerTripsProvider =
    FutureProvider.autoDispose.family<List<AppBookingTrip>, String>((ref, passengerId) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getPassengerTrips(passengerId);
});

final driverTripsProvider = FutureProvider.autoDispose<List<AppTrip>>((ref) async {
  final repository = ref.watch(journeyRepositoryProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null || userId.isEmpty) return const [];
  return repository.getDriverTripsById(userId);
});

final driverTripsByIdProvider =
    FutureProvider.autoDispose.family<List<AppTrip>, String>((ref, driverId) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getDriverTripsById(driverId);
});

final tripBookingsProvider =
    FutureProvider.autoDispose.family<List<AppTripPassenger>, String>((ref, tripId) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getTripBookings(tripId);
});

final popularRoutesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getPopularRoutes();
});

// Provider pour charger tous les trajets actifs (sans filtre)
final allActiveTripsProvider = FutureProvider.autoDispose<List<AppTrip>>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getAllActiveTrips();
});
