class SavedReplayModel {
  const SavedReplayModel({
    required this.id,
    required this.replayId,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String replayId;
  final String userId;
  final DateTime createdAt;

  factory SavedReplayModel.fromJson(Map<String, dynamic> json) {
    return SavedReplayModel(
      id: json['id'] as String,
      replayId: json['replay_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'replay_id': replayId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
