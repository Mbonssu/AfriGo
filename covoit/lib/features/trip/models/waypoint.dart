/// Modèle représentant un point de ramassage (étape intermédiaire) d'un trajet.
/// 
/// Un waypoint est une ville où le chauffeur s'arrête pour prendre ou déposer
/// des passagers entre la ville de départ et la ville d'arrivée.
/// 
/// Exemple : Trajet Douala → Yaoundé avec waypoints à Edéa et Mbalmayo
class Waypoint {
  /// Identifiant unique du waypoint
  final String? id;

  /// ID du trajet parent
  final String? tripId;

  /// Nom de la ville d'étape (ex: "Edéa", "Mbalmayo")
  final String cityName;

  /// Position dans l'ordre du trajet (1 = première étape, 2 = deuxième, etc.)
  final int orderIndex;

  /// Heure estimée d'arrivée à cette étape
  final DateTime estimatedTime;

  /// Date de création du waypoint
  final DateTime? createdAt;

  Waypoint({
    this.id,
    this.tripId,
    required this.cityName,
    required this.orderIndex,
    required this.estimatedTime,
    this.createdAt,
  });

  /// Créer un Waypoint depuis JSON (réponse API)
  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id']?.toString(),
      tripId: json['trip_id']?.toString(),
      cityName: json['city_name'] as String,
      orderIndex: json['order_index'] as int,
      estimatedTime: DateTime.parse(json['estimated_time'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convertir en JSON (pour envoyer à l'API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      'city_name': cityName,
      'order_index': orderIndex,
      'estimated_time': estimatedTime.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Créer une copie avec des modifications
  Waypoint copyWith({
    String? id,
    String? tripId,
    String? cityName,
    int? orderIndex,
    DateTime? estimatedTime,
    DateTime? createdAt,
  }) {
    return Waypoint(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      cityName: cityName ?? this.cityName,
      orderIndex: orderIndex ?? this.orderIndex,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Waypoint(cityName: $cityName, orderIndex: $orderIndex, estimatedTime: $estimatedTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Waypoint &&
        other.id == id &&
        other.tripId == tripId &&
        other.cityName == cityName &&
        other.orderIndex == orderIndex &&
        other.estimatedTime == estimatedTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tripId.hashCode ^
        cityName.hashCode ^
        orderIndex.hashCode ^
        estimatedTime.hashCode;
  }
}
