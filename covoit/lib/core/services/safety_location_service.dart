import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/api_endpoints.dart';
import 'package:flutter/foundation.dart';

/// Service qui envoie automatiquement la position GPS toutes les heures
/// au backend pour notifier le contact d'urgence configuré.
///
/// Démarre automatiquement quand le trajet commence.
/// S'arrête quand le trajet se termine ou que l'écran est fermé.
class SafetyLocationService {
  final dynamic _apiClient;
  final String tripId;
  final String userId;
  final String userName;
  final String tripFrom;
  final String tripTo;
  final String emergencyContactName;
  final String emergencyContactPhone;

  Timer? _timer;
  bool _active = false;

  static const _interval = Duration(hours: 1);

  SafetyLocationService({
    required dynamic apiClient,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.tripFrom,
    required this.tripTo,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  }) : _apiClient = apiClient;

  bool get isActive => _active;

  /// Démarre le service — envoie la position immédiatement puis toutes les heures
  Future<void> start() async {
    if (_active) return;
    _active = true;

    // Vérifier les permissions GPS
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      debugPrint('[Safety] Permissions GPS refusées');
      _active = false;
      return;
    }

    // Envoyer immédiatement la première position
    await _sendLocation();

    // Puis toutes les heures
    _timer = Timer.periodic(_interval, (_) => _sendLocation());
    debugPrint('[Safety] Service démarré pour trip $tripId');
  }

  /// Arrête le service
  void stop() {
    _timer?.cancel();
    _timer = null;
    _active = false;
    debugPrint('[Safety] Service arrêté pour trip $tripId');
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _apiClient.post(
        ApiEndpoints.safetyLocation(tripId),
        data: {
          'user_id': userId,
          'lat': position.latitude,
          'lng': position.longitude,
          'user_name': userName,
          'trip_from': tripFrom,
          'trip_to': tripTo,
          'emergency_contact_name': emergencyContactName,
          'emergency_contact_phone': emergencyContactPhone,
        },
      );

      debugPrint(
          '[Safety] Position envoyée au $emergencyContactPhone: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('[Safety] Erreur envoi position: $e');
    }
  }
}
