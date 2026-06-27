import 'court_model.dart';
import 'replay_model.dart';

enum ArenaStatus { active, inactive }

typedef ArenaId = String;

typedef CourtId = String;

class ArenaModel {
  const ArenaModel({
    required this.id,
    required this.name,
    required this.city,
    this.uf = '',
    required this.isLive,
    required this.replayCount,
    required this.status,
    this.courts = const <CourtModel>[],
    this.replays = const <ReplayModel>[],
  });

  final ArenaId id;
  final String name;
  final String city;
  final String uf;
  final bool isLive;
  final int replayCount;
  final ArenaStatus status;
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
    );
  }
}
