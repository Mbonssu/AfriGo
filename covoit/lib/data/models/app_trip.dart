import 'app_driver_profile.dart';

class AppTrip {
  final String id;
  final String driverId;
  final String from;
  final String to;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final int pricePerSeat;
  final String vehicleModel;
  final String vehiclePlate;
  final String? vehicleId;
  final String status;
  final List<String> comfortOptions;
  final AppDriverProfile driver;

  const AppTrip({
    required this.id,
    required this.driverId,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.vehicleModel,
    required this.vehiclePlate,
    this.vehicleId,
    required this.status,
    required this.comfortOptions,
    required this.driver,
  });

  factory AppTrip.fromApi(
    Map<String, dynamic> json, {
    required AppDriverProfile driver,
  }) {
    return AppTrip(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? driver.userId,
      from: json['departure_city']?.toString() ?? '',
      to: json['arrival_city']?.toString() ?? '',
      departureTime: DateTime.tryParse(json['departure_time']?.toString() ?? '') ??
          DateTime.now(),
      totalSeats: _asInt(json['total_seats']),
      availableSeats: _asInt(json['available_seats']),
      pricePerSeat: _asInt(json['price_per_seat']),
      vehicleModel: json['vehicle_model']?.toString() ?? 'Véhicule non précisé',
      vehiclePlate: json['vehicle_plate']?.toString() ?? 'N/A',
      vehicleId: json['vehicle_id']?.toString(),
      status: json['status']?.toString() ?? 'active',
      comfortOptions: ((json['comfort_options'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      driver: driver,
    );
  }

  int get bookedSeats {
    final seats = totalSeats - availableSeats;
    return seats < 0 ? 0 : seats;
  }

  bool get isBookable => availableSeats > 0 && status == 'active';

  /// Estime la durée du trajet en minutes à partir des villes de départ et d'arrivée.
  /// Couvre les principales liaisons inter-urbaines au Cameroun.
  static int estimateDurationMinutes(String from, String to) {
    final a = from.toLowerCase().trim();
    final b = to.toLowerCase().trim();
    const Map<String, int> _durations = {
      'douala-yaoundé': 210,
      'yaoundé-douala': 210,
      'douala-bafoussam': 240,
      'bafoussam-douala': 240,
      'yaoundé-bafoussam': 180,
      'bafoussam-yaoundé': 180,
      'douala-limbé': 90,
      'limbé-douala': 90,
      'douala-buea': 90,
      'buea-douala': 90,
      'yaoundé-bertoua': 300,
      'bertoua-yaoundé': 300,
      'yaoundé-kribi': 150,
      'kribi-yaoundé': 150,
      'douala-kribi': 120,
      'kribi-douala': 120,
      'bafoussam-bamenda': 90,
      'bamenda-bafoussam': 90,
      'yaoundé-ebolowa': 180,
      'ebolowa-yaoundé': 180,
      'yaoundé-ngaoundéré': 540,
      'ngaoundéré-yaoundé': 540,
      'douala-ngaoundéré': 600,
      'ngaoundéré-douala': 600,
      'yaoundé-garoua': 720,
      'garoua-yaoundé': 720,
      'douala-garoua': 840,
      'garoua-douala': 840,
      'bamenda-yaoundé': 300,
      'yaoundé-bamenda': 300,
      'bamenda-douala': 270,
      'douala-bamenda': 270,
    };
    final key = '$a-$b';
    return _durations[key] ?? 270; // 4h30 par défaut
  }

  /// Estime la distance en km entre deux villes camerounaises.
  static int estimateDistanceKm(String from, String to) {
    final a = from.toLowerCase().trim();
    final b = to.toLowerCase().trim();
    const Map<String, int> _distances = {
      'douala-yaoundé': 240,
      'yaoundé-douala': 240,
      'douala-bafoussam': 270,
      'bafoussam-douala': 270,
      'yaoundé-bafoussam': 186,
      'bafoussam-yaoundé': 186,
      'douala-limbé': 88,
      'limbé-douala': 88,
      'douala-buea': 85,
      'buea-douala': 85,
      'yaoundé-bertoua': 350,
      'bertoua-yaoundé': 350,
      'yaoundé-kribi': 170,
      'kribi-yaoundé': 170,
      'douala-kribi': 155,
      'kribi-douala': 155,
      'bafoussam-bamenda': 90,
      'bamenda-bafoussam': 90,
      'yaoundé-ebolowa': 160,
      'ebolowa-yaoundé': 160,
      'bamenda-yaoundé': 360,
      'yaoundé-bamenda': 360,
      'bamenda-douala': 340,
      'douala-bamenda': 340,
    };
    final key = '$a-$b';
    return _distances[key] ?? 250;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
