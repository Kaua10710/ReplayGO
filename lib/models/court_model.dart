class CourtModel {
  const CourtModel({
    required this.id,
    required this.arenaId,
    required this.name,
    required this.isLive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String arenaId;
  final String name;
  final bool isLive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'] as String,
      arenaId: json['arena_id'] as String,
      name: json['name'] as String,
      isLive: json['is_live'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arena_id': arenaId,
      'name': name,
      'is_live': isLive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
