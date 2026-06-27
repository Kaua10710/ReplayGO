import 'court_model.dart';
import 'replay_model.dart';

enum ArenaStatus { active, inactive }

class ArenaModel {
  const ArenaModel({
    required this.id,
    required this.name,
    required this.city,
    this.uf = '',
    required this.status,
    required this.isLive,
    required this.replayCount,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.courts = const <CourtModel>[],
    this.replays = const <ReplayModel>[],
  });

  final String id;
  final String? ownerId;
  final String name;
  final String city;
  final String uf;
  final ArenaStatus status;
  final bool isLive;
  final int replayCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CourtModel> courts;
  final List<ReplayModel> replays;

  ArenaModel copyWith({
    String? name,
    String? city,
    String? uf,
    bool? isLive,
    int? replayCount,
    ArenaStatus? status,
    List<CourtModel>? courts,
    List<ReplayModel>? replays,
  }) {
    return ArenaModel(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      uf: uf ?? this.uf,
      isLive: isLive ?? this.isLive,
      replayCount: replayCount ?? this.replayCount,
      status: status ?? this.status,
      courts: courts ?? this.courts,
      replays: replays ?? this.replays,
  factory ArenaModel.fromJson(Map<String, dynamic> json) {
    return ArenaModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String,
      city: json['city'] as String,
      status: _statusFromString(json['status'] as String),
      isLive: json['is_live'] as bool? ?? false,
      replayCount: (json['replay_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      courts: (json['courts'] as List<dynamic>? ?? [])
          .map((court) => CourtModel.fromJson(court as Map<String, dynamic>))
          .toList(),
      replays: (json['replays'] as List<dynamic>? ?? [])
          .map((replay) => ReplayModel.fromJson(replay as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'city': city,
      'status': status.name,
      'is_live': isLive,
      'replay_count': replayCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'courts': courts.map((court) => court.toJson()).toList(),
      'replays': replays.map((replay) => replay.toJson()).toList(),
    };
  }

  static ArenaStatus _statusFromString(String value) {
    return ArenaStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ArenaStatus.active,
    );
  }
}
