import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/arena_model.dart';
import '../models/city_model.dart';
import '../utils/supabase_replay_mapper.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.arenas,
    required this.cities,
    required this.totalUsers,
    required this.totalReplays,
  });

  final List<ArenaModel> arenas;
  final List<CityModel> cities;
  final int totalUsers;
  final int totalReplays;

  int get totalCities => cities.length;
  int get totalArenas => arenas.length;
}

/// Contrato consumido pelo `AdminController`. Permite injetar uma implementação
/// fake nos testes sem depender do Supabase.
abstract class AdminDataSource {
  Future<AdminDashboardData> loadDashboard();

  Future<ArenaModel> createArena({
    required String name,
    required String city,
    required String uf,
    bool isLive = false,
    int replayCount = 0,
    ArenaStatus status = ArenaStatus.active,
    String? ownerId,
  });

  Future<void> updateArena(
    String id, {
    String? name,
    String? city,
    String? uf,
    bool? isLive,
    int? replayCount,
    ArenaStatus? status,
  });

  Future<void> deleteArena(String id);

  Future<CityModel> createCity({required String name, required String uf});

  Future<void> updateCity(String id, {String? name, String? uf});

  Future<void> deleteCity(String id);

  Future<bool> cityExists(String name, String uf);
}

class AdminService implements AdminDataSource {
  AdminService();

  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<AdminDashboardData> loadDashboard() async {
    final results = await Future.wait([
      _fetchArenasInternal(),
      _fetchCitiesInternal(),
      _client.from('profiles').select('id'),
      _client.from('replays').select('id'),
    ]);

    final arenas = results[0] as List<ArenaModel>;
    final cities = results[1] as List<CityModel>;
    final users = results[2] as List<dynamic>;
    final replays = results[3] as List<dynamic>;

    return AdminDashboardData(
      arenas: arenas,
      cities: cities,
      totalUsers: users.length,
      totalReplays: replays.length,
    );
  }

  Future<List<ArenaModel>> fetchArenas() => _fetchArenasInternal();

  Future<List<CityModel>> fetchCities() => _fetchCitiesInternal();

  @override
  Future<ArenaModel> createArena({
    required String name,
    required String city,
    required String uf,
    bool isLive = false,
    int replayCount = 0,
    ArenaStatus status = ArenaStatus.active,
    String? ownerId,
  }) async {
    final response = await _client.from('arenas').insert({
      'name': name.trim(),
      'city': city.trim(),
      'uf': uf.trim().toUpperCase(),
      'is_live': isLive,
      'replay_count': replayCount,
      'status': status.name,
      'owner_id': ownerId,
    }).select().maybeSingle();

    if (response == null) {
      throw Exception('Não foi possível criar a arena.');
    }

    return ArenaModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> updateArena(
    String id, {
    String? name,
    String? city,
    String? uf,
    bool? isLive,
    int? replayCount,
    ArenaStatus? status,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (city != null) payload['city'] = city.trim();
    if (uf != null) payload['uf'] = uf.trim().toUpperCase();
    if (isLive != null) payload['is_live'] = isLive;
    if (replayCount != null) payload['replay_count'] = replayCount;
    if (status != null) payload['status'] = status.name;

    if (payload.isEmpty) {
      return;
    }

    await _client.from('arenas').update(payload).eq('id', id);
  }

  @override
  Future<void> deleteArena(String id) async {
    await _client.from('arenas').delete().eq('id', id);
  }

  @override
  Future<CityModel> createCity({
    required String name,
    required String uf,
  }) async {
    final response = await _client.from('cities').insert({
      'name': name.trim(),
      'uf': uf.trim().toUpperCase(),
    }).select().maybeSingle();

    if (response == null) {
      throw Exception('Não foi possível cadastrar a cidade.');
    }

    return CityModel.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> updateCity(
    String id, {
    String? name,
    String? uf,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (uf != null) payload['uf'] = uf.trim().toUpperCase();
    if (payload.isEmpty) return;

    await _client.from('cities').update(payload).eq('id', id);
  }

  @override
  Future<void> deleteCity(String id) async {
    await _client.from('cities').delete().eq('id', id);
  }

  @override
  Future<bool> cityExists(String name, String uf) async {
    final response = await _client
        .from('cities')
        .select('id')
        .eq('name', name.trim())
        .eq('uf', uf.trim().toUpperCase());
    return (response as List<dynamic>).isNotEmpty;
  }

  Future<List<ArenaModel>> _fetchArenasInternal() async {
    final response = await _client
        .from('arenas')
        .select(
          '''
            id,
            owner_id,
            name,
            city,
            uf,
            status,
            is_live,
            replay_count,
            created_at,
            updated_at,
            courts (*),
            replays (
              id,
              arena_id,
              court_id,
              owner_id,
              title,
              description,
              duration_seconds,
              recorded_at,
              visibility,
              created_at,
              updated_at,
              arenas:arena_id(name),
              courts:court_id(name)
            )
          ''',
        )
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      map['courts'] = (map['courts'] as List<dynamic>? ?? [])
          .map((court) => Map<String, dynamic>.from(court as Map<String, dynamic>))
          .toList();
      map['replays'] = (map['replays'] as List<dynamic>? ?? [])
          .map((replay) => normalizeReplayRow(Map<String, dynamic>.from(replay as Map<String, dynamic>)))
          .toList();
      return ArenaModel.fromJson(map);
    }).toList();
  }

  Future<List<CityModel>> _fetchCitiesInternal() async {
    final response = await _client
        .from('cities')
        .select('id, name, uf')
        .order('name');

    return (response as List<dynamic>)
        .map((item) => CityModel.fromJson(Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }
}
