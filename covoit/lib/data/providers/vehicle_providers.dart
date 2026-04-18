import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../models/app_vehicle.dart';
import '../repositories/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return VehicleRepository(client);
});

final vehiclesProvider =
    FutureProvider.autoDispose.family<List<AppVehicle>, String>((ref, userId) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.listVehicles(userId);
});
