import 'package:flutter/foundation.dart';

import '../models/arena_model.dart';
import '../models/camera_model.dart';
import '../models/city_model.dart';
import '../models/court_model.dart';
import '../models/profile_model.dart';
import '../models/replay_model.dart';
import '../models/saved_replay_model.dart';

class MockService extends ChangeNotifier {
  MockService();

  final List<ProfileModel> _profiles = [
    ProfileModel(
      id: 'profile-user',
      email: 'lucas@replaygo.com',
      name: 'Lucas Carvalho',
      role: UserRole.user,
      sport: 'Beach Volley',
      notifications: 12,
      createdAt: DateTime.utc(2024, 1, 10, 13),
      updatedAt: DateTime.utc(2024, 5, 20, 8),
    ),
    ProfileModel(
      id: 'profile-owner',
      email: 'arena@replaygo.com',
      name: 'Arena Beira Mar',
      role: UserRole.owner,
      sport: 'Praia de Iracema, Fortaleza',
      notifications: 3,
      createdAt: DateTime.utc(2024, 2, 4, 14),
      updatedAt: DateTime.utc(2024, 5, 25, 10),
    ),
    ProfileModel(
      id: 'profile-admin',
      email: 'admin@replaygo.com',
      name: 'AD',
      role: UserRole.admin,
      sport: 'Full Access',
      createdAt: DateTime.utc(2024, 3, 18, 11),
      updatedAt: DateTime.utc(2024, 5, 25, 11),
    ),
  ];

  final List<ArenaModel> _arenas = [
    ArenaModel(
      id: 'arena-1',
      ownerId: 'profile-owner',
      name: 'Arena Beira Mar',
      city: 'Fortaleza',
      uf: 'CE',
      status: ArenaStatus.active,
      isLive: true,
      replayCount: 28,
      createdAt: DateTime.utc(2024, 3, 12, 9),
      updatedAt: DateTime.utc(2024, 5, 25, 12),
      courts: [
        CourtModel(
          id: 'court-1',
          arenaId: 'arena-1',
          name: 'Quadra 1',
          isLive: true,
          createdAt: DateTime.utc(2024, 3, 12, 10),
          updatedAt: DateTime.utc(2024, 5, 25, 12),
        ),
        CourtModel(
          id: 'court-2',
          arenaId: 'arena-1',
          name: 'Quadra 2',
          isLive: false,
          createdAt: DateTime.utc(2024, 3, 12, 10, 30),
          updatedAt: DateTime.utc(2024, 5, 20, 16),
        ),
        CourtModel(
          id: 'court-3',
          arenaId: 'arena-1',
          name: 'Quadra 3',
          isLive: false,
          createdAt: DateTime.utc(2024, 3, 12, 11),
          updatedAt: DateTime.utc(2024, 5, 18, 15),
        ),
      ],
      replays: [
        ReplayModel(
          id: 'replay-1',
          arenaId: 'arena-1',
          courtId: 'court-1',
          ownerId: 'profile-owner',
          title: 'Ponto decisivo',
          description: 'Match point que garantiu a vitória.',
          durationSeconds: 42,
          recordedAt: DateTime.utc(2024, 5, 26, 19, 12),
          visibility: ReplayVisibility.public,
          createdAt: DateTime.utc(2024, 5, 26, 19, 13),
          updatedAt: DateTime.utc(2024, 5, 26, 19, 15),
          courtName: 'Quadra 1',
          arenaName: 'Arena Beira Mar',
        ),
        ReplayModel(
          id: 'replay-2',
          arenaId: 'arena-1',
          courtId: 'court-1',
          ownerId: 'profile-owner',
          title: 'Defesa absurda',
          description: 'Salvamento impressionante na areia.',
          durationSeconds: 65,
          recordedAt: DateTime.utc(2024, 5, 26, 18, 34),
          visibility: ReplayVisibility.public,
          createdAt: DateTime.utc(2024, 5, 26, 18, 35),
          updatedAt: DateTime.utc(2024, 5, 26, 18, 40),
          courtName: 'Quadra 1',
          arenaName: 'Arena Beira Mar',
        ),
        ReplayModel(
          id: 'replay-3',
          arenaId: 'arena-1',
          courtId: 'court-2',
          ownerId: 'profile-owner',
          title: 'Cortada cruzada',
          durationSeconds: 28,
          recordedAt: DateTime.utc(2024, 5, 26, 16, 5),
          visibility: ReplayVisibility.public,
          createdAt: DateTime.utc(2024, 5, 26, 16, 6),
          updatedAt: DateTime.utc(2024, 5, 26, 16, 6),
          courtName: 'Quadra 2',
          arenaName: 'Arena Beira Mar',
        ),
        ReplayModel(
          id: 'replay-4',
          arenaId: 'arena-1',
          courtId: 'court-3',
          ownerId: 'profile-owner',
          title: 'Bloqueio duplo',
          durationSeconds: 51,
          recordedAt: DateTime.utc(2024, 5, 26, 15, 10),
          visibility: ReplayVisibility.public,
          createdAt: DateTime.utc(2024, 5, 26, 15, 11),
          updatedAt: DateTime.utc(2024, 5, 26, 15, 12),
          courtName: 'Quadra 3',
          arenaName: 'Arena Beira Mar',
        ),
        ReplayModel(
          id: 'replay-5',
          arenaId: 'arena-1',
          courtId: 'court-1',
          ownerId: 'profile-owner',
          title: 'Saque viagem',
          durationSeconds: 90,
          recordedAt: DateTime.utc(2024, 4, 30, 18),
          visibility: ReplayVisibility.expired,
          createdAt: DateTime.utc(2024, 4, 30, 18, 1),
          updatedAt: DateTime.utc(2024, 5, 15, 12),
          courtName: 'Quadra 1',
          arenaName: 'Arena Beira Mar',
        ),
        ReplayModel(
          id: 'replay-6',
          arenaId: 'arena-1',
          courtId: 'court-2',
          ownerId: 'profile-owner',
          title: 'Bloqueio',
          durationSeconds: 88,
          recordedAt: DateTime.utc(2024, 4, 22, 17, 20),
          visibility: ReplayVisibility.expired,
          createdAt: DateTime.utc(2024, 4, 22, 17, 21),
          updatedAt: DateTime.utc(2024, 5, 10, 9),
          courtName: 'Quadra 2',
          arenaName: 'Arena Beira Mar',
        ),
      ],
    ),
    ArenaModel(
      id: 'arena-2',
      ownerId: 'profile-owner',
      name: 'Quadra do Zé',
      city: 'Recife',
      uf: 'PE',
      status: ArenaStatus.active,
      isLive: false,
      replayCount: 12,
      createdAt: DateTime.utc(2024, 1, 22, 9),
      updatedAt: DateTime.utc(2024, 5, 18, 14),
    ),
    ArenaModel(
      id: 'arena-3',
      ownerId: 'profile-owner',
      name: 'Areia Club',
      city: 'Florianópolis',
      uf: 'SC',
      status: ArenaStatus.active,
      isLive: true,
      replayCount: 41,
      createdAt: DateTime.utc(2024, 2, 11, 8),
      updatedAt: DateTime.utc(2024, 5, 20, 16),
    ),
    ArenaModel(
      id: 'arena-4',
      ownerId: 'profile-owner',
      name: 'Praia FC',
      city: 'Salvador',
      uf: 'BA',
      status: ArenaStatus.inactive,
      isLive: false,
      replayCount: 0,
      createdAt: DateTime.utc(2023, 12, 4, 10),
      updatedAt: DateTime.utc(2024, 4, 18, 13),
    ),
    ArenaModel(
      id: 'arena-5',
      ownerId: 'profile-owner',
      name: 'Sand Center',
      city: 'Rio de Janeiro',
      uf: 'RJ',
      status: ArenaStatus.active,
      isLive: false,
      replayCount: 17,
      createdAt: DateTime.utc(2024, 1, 14, 7),
      updatedAt: DateTime.utc(2024, 5, 12, 9),
    ),
    ArenaModel(
      id: 'arena-6',
      ownerId: 'profile-owner',
      name: 'Arena Sul',
      city: 'Porto Alegre',
      uf: 'RS',
      status: ArenaStatus.inactive,
      isLive: false,
      replayCount: 3,
      createdAt: DateTime.utc(2024, 3, 4, 13),
      updatedAt: DateTime.utc(2024, 5, 4, 13),
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

  final List<SavedReplayModel> _savedReplays = [
    SavedReplayModel(
      id: 'saved-1',
      replayId: 'replay-1',
      userId: 'profile-user',
      createdAt: DateTime.utc(2024, 5, 26, 19, 20),
    ),
    SavedReplayModel(
      id: 'saved-2',
      replayId: 'replay-2',
      userId: 'profile-user',
      createdAt: DateTime.utc(2024, 5, 26, 18, 45),
    ),
  ];

  ProfileModel getProfile(UserRole role) =>
      _profiles.firstWhere((profile) => profile.role == role);

  @Deprecated('Use getProfile')
  ProfileModel getUser(UserRole role) => getProfile(role);

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
    final now = DateTime.now();
    final arena = ArenaModel(
      id: 'arena-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      city: city.trim(),
      uf: uf.trim().toUpperCase(),
      isLive: isLive,
      replayCount: replayCount,
      status: status,
      createdAt: now,
      updatedAt: now,
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
  List<ReplayModel> replaysForArena(String arenaId) =>
      List.unmodifiable(getArenaById(arenaId).replays);

  List<SavedReplayModel> savedReplaysForUser(String userId) => List.unmodifiable(
        _savedReplays.where((saved) => saved.userId == userId),
      );

  ReplayModel? getReplayById(String replayId) {
    for (final arena in _arenas) {
      for (final replay in arena.replays) {
        if (replay.id == replayId) {
          return replay;
        }
      }
    }
    return null;
  }

  List<CameraModel> get cameras => List.unmodifiable(_cameras);
}
