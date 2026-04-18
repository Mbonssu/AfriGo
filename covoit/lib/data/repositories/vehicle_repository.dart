import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/app_vehicle.dart';

class VehicleRepository {
  final ApiClient _client;

  VehicleRepository(this._client);

  Future<List<AppVehicle>> listVehicles(String userId) async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.vehicles(userId),
    );
    return response
        .whereType<Map>()
        .map((item) => AppVehicle.fromApi(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AppVehicle> createVehicle({
    required String userId,
    required String brand,
    required String model,
    int? year,
    String? color,
    required String plate,
    int seats = 4,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.vehicles(userId),
      data: {
        'brand': brand,
        'model': model,
        if (year != null) 'year': year,
        if (color != null) 'color': color,
        'plate': plate,
        'seats': seats,
      },
    );
    return AppVehicle.fromApi(response);
  }

  Future<AppVehicle> updateVehicle({
    required String userId,
    required String vehicleId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    int? seats,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.vehicleById(userId, vehicleId),
      data: {
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (color != null) 'color': color,
        if (plate != null) 'plate': plate,
        if (seats != null) 'seats': seats,
      },
    );
    return AppVehicle.fromApi(response);
  }

  Future<void> deleteVehicle({
    required String userId,
    required String vehicleId,
  }) {
    return _client.delete(ApiEndpoints.vehicleById(userId, vehicleId));
  }

  Future<AppVehiclePhoto> uploadPhoto({
    required String userId,
    required String vehicleId,
    required File imageFile,
    int position = 0,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      'position': position,
    });

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.vehiclePhotos(userId, vehicleId),
      data: formData,
    );
    return AppVehiclePhoto.fromApi(response);
  }

  Future<void> deletePhoto({
    required String userId,
    required String vehicleId,
    required String photoId,
  }) {
    return _client.delete(
      ApiEndpoints.vehiclePhotoById(userId, vehicleId, photoId),
    );
  }
}
