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
    required this.isLive,
    required this.replayCount,
    required this.status,
    this.courts = const <CourtModel>[],
    this.replays = const <ReplayModel>[],
  });

  final ArenaId id;
  final String name;
  final String city;
  final bool isLive;
  final int replayCount;
  final ArenaStatus status;
  final List<CourtModel> courts;
  final List<ReplayModel> replays;
}
