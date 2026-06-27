import 'court_model.dart';
import 'replay_model.dart';

enum ArenaStatus { active, inactive }

class ArenaModel {
  const ArenaModel({
    required this.id,
    required this.name,
    required this.city,
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
  final bool isLive;
  final int replayCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CourtModel> courts;
  final List<ReplayModel> replays;
}
