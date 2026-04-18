class AppVehicle {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int? year;
  final String? color;
  final String plate;
  final int seats;
  final List<AppVehiclePhoto> photos;
  final DateTime createdAt;

  const AppVehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.year,
    this.color,
    required this.plate,
    required this.seats,
    this.photos = const [],
    required this.createdAt,
  });

  String get displayName => '$brand $model${year != null ? ' ($year)' : ''}';

  String get displayPlate => plate;

  factory AppVehicle.fromApi(Map<String, dynamic> json) {
    return AppVehicle(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year'] is int ? json['year'] as int : int.tryParse(json['year']?.toString() ?? ''),
      color: json['color']?.toString(),
      plate: json['plate']?.toString() ?? '',
      seats: _asInt(json['seats'], fallback: 4),
      photos: ((json['photos'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => AppVehiclePhoto.fromApi(Map<String, dynamic>.from(p)))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class AppVehiclePhoto {
  final String id;
  final String photoUrl;
  final int position;
  final Map<String, dynamic>? aiAnalysis;

  const AppVehiclePhoto({
    required this.id,
    required this.photoUrl,
    required this.position,
    this.aiAnalysis,
  });

  String? get aiStatus => aiAnalysis?['status']?.toString();

  String? get aiReason => aiAnalysis?['reason']?.toString();

  factory AppVehiclePhoto.fromApi(Map<String, dynamic> json) {
    return AppVehiclePhoto(
      id: json['id']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      position: json['position'] is int ? json['position'] as int : 0,
      aiAnalysis: json['ai_analysis'] is Map
          ? Map<String, dynamic>.from(json['ai_analysis'] as Map)
          : null,
    );
  }
}
