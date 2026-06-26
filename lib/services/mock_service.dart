import '../models/arena_model.dart';
import '../models/camera_model.dart';
import '../models/court_model.dart';
import '../models/replay_model.dart';
import '../models/user_model.dart';

class MockService {
  MockService();

  final List<UserModel> _users = const [
    UserModel(
      name: 'Lucas Carvalho',
      username: '@lucascarv',
      sport: 'Beach Volley',
      replaysSaved: 42,
      role: UserRole.user,
      notifications: 12,
    ),
    UserModel(
      name: 'Arena Beira Mar',
      username: '@arenabeiramar',
      sport: 'Praia de Iracema, Fortaleza',
      replaysSaved: 3,
      role: UserRole.owner,
    ),
    UserModel(
      name: 'AD',
      username: '@admin',
      sport: 'Full Access',
      replaysSaved: 0,
      role: UserRole.admin,
    ),
  ];

  final List<ArenaModel> _arenas = [
    ArenaModel(
      id: 'arena-1',
      name: 'Arena Beira Mar',
      city: 'Fortaleza',
      isLive: true,
      replayCount: 28,
      status: ArenaStatus.active,
      courts: const [
        CourtModel(id: 'court-1', name: 'Quadra 1', isLive: true),
        CourtModel(id: 'court-2', name: 'Quadra 2', isLive: false),
        CourtModel(id: 'court-3', name: 'Quadra 3', isLive: false),
      ],
      replays: const [
        ReplayModel(
          title: 'Ponto decisivo',
          courtName: 'Quadra 1',
          duration: '0:42',
          timeAgo: 'há 12 min',
          visibility: ReplayVisibility.public,
        ),
        ReplayModel(
          title: 'Defesa absurda',
          courtName: 'Quadra 1',
          duration: '1:05',
          timeAgo: 'há 38 min',
          visibility: ReplayVisibility.public,
        ),
        ReplayModel(
          title: 'Cortada cruzada',
          courtName: 'Quadra 2',
          duration: '0:28',
          timeAgo: 'há 1h',
          visibility: ReplayVisibility.public,
        ),
        ReplayModel(
          title: 'Bloqueio duplo',
          courtName: 'Quadra 3',
          duration: '0:51',
          timeAgo: 'há 2h',
          visibility: ReplayVisibility.public,
        ),
        ReplayModel(
          title: 'Saque viagem',
          courtName: 'Quadra 1',
          duration: 'older',
          timeAgo: 'expirado',
          visibility: ReplayVisibility.expired,
        ),
        ReplayModel(
          title: 'Bloqueio',
          courtName: 'Quadra 2',
          duration: 'older',
          timeAgo: 'expirado',
          visibility: ReplayVisibility.expired,
        ),
      ],
    ),
    const ArenaModel(
      id: 'arena-2',
      name: 'Quadra do Zé',
      city: 'Recife',
      isLive: false,
      replayCount: 12,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-3',
      name: 'Areia Club',
      city: 'Florianópolis',
      isLive: true,
      replayCount: 41,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-4',
      name: 'Praia FC',
      city: 'Salvador',
      isLive: false,
      replayCount: 0,
      status: ArenaStatus.inactive,
    ),
    const ArenaModel(
      id: 'arena-5',
      name: 'Sand Center',
      city: 'Rio de Janeiro',
      isLive: false,
      replayCount: 17,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-6',
      name: 'Arena Sul',
      city: 'Porto Alegre',
      isLive: false,
      replayCount: 3,
      status: ArenaStatus.inactive,
    ),
  ];

  final List<CameraModel> _cameras = const [
    CameraModel(id: 'cam-1', name: 'Câmera central', isActive: true),
    CameraModel(id: 'cam-2', name: 'Câmera lateral', isActive: true),
    CameraModel(id: 'cam-3', name: 'Câmera aérea', isActive: true),
    CameraModel(id: 'cam-4', name: 'Câmera reserva', isActive: false),
  ];

  UserModel getUser(UserRole role) =>
      _users.firstWhere((user) => user.role == role);

  List<ArenaModel> get arenas => _arenas;

  ArenaModel getArenaById(String id) =>
      _arenas.firstWhere((arena) => arena.id == id);

  List<ReplayModel> replaysForArena(String arenaId) {
    return _arenas
        .firstWhere((arena) => arena.id == arenaId)
        .replays;
  }

  List<CameraModel> get cameras => _cameras;
}
