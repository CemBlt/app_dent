enum FavoriteType {
  hospital,
  doctor,
  service;

  String get value {
    switch (this) {
      case FavoriteType.hospital:
        return 'hospital';
      case FavoriteType.doctor:
        return 'doctor';
      case FavoriteType.service:
        return 'service';
    }
  }

  static FavoriteType fromString(String raw) {
    switch (raw) {
      case 'doctor':
        return FavoriteType.doctor;
      case 'service':
        return FavoriteType.service;
      default:
        return FavoriteType.hospital;
    }
  }
}

class Favorite {
  final String id;
  final String userId;
  final String targetId;
  final FavoriteType type;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      targetId: json['target_id'].toString(),
      type: FavoriteType.fromString(json['target_type']?.toString() ?? 'hospital'),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}


