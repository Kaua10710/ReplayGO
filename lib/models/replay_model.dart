enum ReplayVisibility { public, expired }

class ReplayModel {
  const ReplayModel({
    required this.id,
    required this.arenaId,
    required this.title,
    required this.durationSeconds,
    required this.recordedAt,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.courtId,
    this.ownerId,
    this.description,
    this.courtName,
    this.arenaName,
  });

  final String id;
  final String arenaId;
  final String? courtId;
  final String? ownerId;
  final String title;
  final String? description;
  final int durationSeconds;
  final DateTime recordedAt;
  final ReplayVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? courtName;
  final String? arenaName;

  factory ReplayModel.fromJson(Map<String, dynamic> json) {
    return ReplayModel(
      id: json['id'] as String,
      arenaId: json['arena_id'] as String,
      courtId: json['court_id'] as String?,
      ownerId: json['owner_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      visibility: _visibilityFromString(json['visibility'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      courtName: json['court_name'] as String?,
      arenaName: json['arena_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arena_id': arenaId,
      'court_id': courtId,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'duration_seconds': durationSeconds,
      'recorded_at': recordedAt.toIso8601String(),
      'visibility': visibility.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get durationLabel {
    final duration = Duration(seconds: durationSeconds);
    final minutes = duration.inMinutes.remainder(60).clamp(0, 59).toString().padLeft(1, '0');
    final seconds = (duration.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }

  String get timeAgoLabel {
    final now = DateTime.now();
    final difference = now.difference(recordedAt);

    if (difference.inMinutes < 1) {
      return 'agora';
    }
    if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'há ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'há ${difference.inDays} dias';
    }
    return '${recordedAt.day}/${recordedAt.month}/${recordedAt.year}';
  }

  static ReplayVisibility _visibilityFromString(String value) {
    return ReplayVisibility.values.firstWhere(
      (visibility) => visibility.name == value,
      orElse: () => ReplayVisibility.public,
    );
  }
}
