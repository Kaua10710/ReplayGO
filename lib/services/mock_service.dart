import 'package:flutter/foundation.dart';

import '../models/arena_model.dart';
import '../models/camera_model.dart';
import '../models/city_model.dart';
import '../models/court_model.dart';
import '../models/replay_model.dart';
import '../models/user_model.dart';

class MockService extends ChangeNotifier {
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
    const ArenaModel(
      id: 'arena-1',
      name: 'Arena Beira Mar',
      city: 'Fortaleza',
      uf: 'CE',
      isLive: true,
      replayCount: 28,
      status: ArenaStatus.active,
      courts: [
        CourtModel(id: 'court-1', name: 'Quadra 1', isLive: true),
        CourtModel(id: 'court-2', name: 'Quadra 2', isLive: false),
        CourtModel(id: 'court-3', name: 'Quadra 3', isLive: false),
      ],
      replays: [
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
      uf: 'PE',
      isLive: false,
      replayCount: 12,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-3',
      name: 'Areia Club',
      city: 'Florianópolis',
      uf: 'SC',
      isLive: true,
      replayCount: 41,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-4',
      name: 'Praia FC',
      city: 'Salvador',
      uf: 'BA',
      isLive: false,
      replayCount: 0,
      status: ArenaStatus.inactive,
    ),
    const ArenaModel(
      id: 'arena-5',
      name: 'Sand Center',
      city: 'Rio de Janeiro',
      uf: 'RJ',
      isLive: false,
      replayCount: 17,
      status: ArenaStatus.active,
    ),
    const ArenaModel(
      id: 'arena-6',
      name: 'Arena Sul',
      city: 'Porto Alegre',
      uf: 'RS',
      isLive: false,
      replayCount: 3,
      status: ArenaStatus.inactive,
    ),
  ];

  final List<CityModel> _cities = [
    const CityModel(id: 'city-1', name: 'Fortaleza', uf: 'CE'),
    const CityModel(id: 'city-2', name: 'Recife', uf: 'PE'),
    const CityModel(id: 'city-3', name: 'Florianópolis', uf: 'SC'),
    const CityModel(id: 'city-4', name: 'Salvador', uf: 'BA'),
    const CityModel(id: 'city-5', name: 'Rio de Janeiro', uf: 'RJ'),
    const CityModel(id: 'city-6', name: 'Porto Alegre', uf: 'RS'),
  ];

  final List<CameraModel> _cameras = const [
    CameraModel(id: 'cam-1', name: 'Câmera central', isActive: true),
    CameraModel(id: 'cam-2', name: 'Câmera lateral', isActive: true),
    CameraModel(id: 'cam-3', name: 'Câmera aérea', isActive: true),
    CameraModel(id: 'cam-4', name: 'Câmera reserva', isActive: false),
  ];

  UserModel getUser(UserRole role) =>
      _users.firstWhere((user) => user.role == role);

  List<ArenaModel> get arenas => List.unmodifiable(_arenas);

  ArenaModel getArenaById(String id) =>
      _arenas.firstWhere((arena) => arena.id == id);

  // ---------------------------------------------------------------------------
  // CRUD de arenas (usado pelo painel admin)
  // ---------------------------------------------------------------------------

  ArenaModel addArena({
    required String name,
    required String city,
    required String uf,
    bool isLive = false,
    int replayCount = 0,
    ArenaStatus status = ArenaStatus.active,
  }) {
    final arena = ArenaModel(
      id: 'arena-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      city: city.trim(),
      uf: uf.trim().toUpperCase(),
      isLive: isLive,
      replayCount: replayCount,
      status: status,
    );
    _arenas.add(arena);
    notifyListeners();
    return arena;
  }

  void updateArena(
    String id, {
    String? name,
    String? city,
    String? uf,
    bool? isLive,
    int? replayCount,
    ArenaStatus? status,
  }) {
    final index = _arenas.indexWhere((arena) => arena.id == id);
    if (index == -1) return;
    _arenas[index] = _arenas[index].copyWith(
      name: name,
      city: city,
      uf: uf,
      isLive: isLive,
      replayCount: replayCount,
      status: status,
    );
    notifyListeners();
  }

  void removeArena(String id) {
    _arenas.removeWhere((arena) => arena.id == id);
    notifyListeners();
  }

  List<ReplayModel> replaysForArena(String arenaId) {
    return _arenas
        .firstWhere((arena) => arena.id == arenaId)
        .replays;
  }

  List<CameraModel> get cameras => _cameras;

  List<CityModel> get cities => List.unmodifiable(_cities);

  /// Arenas pertencentes a uma cidade (casa por nome, ignorando caixa/acentos
  /// triviais de digitação).
  List<ArenaModel> arenasForCity(CityModel city) {
    final target = city.name.trim().toLowerCase();
    return _arenas
        .where((arena) => arena.city.trim().toLowerCase() == target)
        .toList();
  }

  bool cityExists(String name, String uf) {
    final n = name.trim().toLowerCase();
    final u = uf.trim().toLowerCase();
    return _cities.any(
      (c) => c.name.trim().toLowerCase() == n && c.uf.trim().toLowerCase() == u,
    );
  }

  /// Cadastra uma cidade (usado pelo painel admin). A home do usuário observa
  /// este serviço, então a nova seção aparece imediatamente.
  CityModel addCity(String name, String uf) {
    final city = CityModel(
      id: 'city-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      uf: uf.trim().toUpperCase(),
    );
    _cities.add(city);
    notifyListeners();
    return city;
  }

  void updateCity(String id, {String? name, String? uf}) {
    final index = _cities.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _cities[index] = _cities[index].copyWith(
      name: name?.trim(),
      uf: uf?.trim().toUpperCase(),
    );
    notifyListeners();
  }

  void removeCity(String id) {
    _cities.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
