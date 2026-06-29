import 'package:flutter_test/flutter_test.dart';
import 'package:replaygo/models/arena_model.dart';
import 'package:replaygo/models/city_model.dart';
import 'package:replaygo/providers/admin_controller.dart';
import 'package:replaygo/services/admin_service.dart';

ArenaModel _arena(String id, String name, String city, String uf) {
  final now = DateTime.utc(2024, 1, 1);
  return ArenaModel(
    id: id,
    name: name,
    city: city,
    uf: uf,
    isLive: false,
    replayCount: 0,
    status: ArenaStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

/// Implementação em memória de [AdminDataSource] — substitui o Supabase nos
/// testes do controller.
class FakeAdminDataSource implements AdminDataSource {
  List<ArenaModel> arenas = [];
  List<CityModel> cities = [];
  int totalUsers = 0;
  int totalReplays = 0;
  bool throwOnLoad = false;
  int loadCalls = 0;

  @override
  Future<AdminDashboardData> loadDashboard() async {
    loadCalls++;
    if (throwOnLoad) {
      throw Exception('falha simulada ao carregar');
    }
    return AdminDashboardData(
      arenas: List.of(arenas),
      cities: List.of(cities),
      totalUsers: totalUsers,
      totalReplays: totalReplays,
    );
  }

  @override
  Future<CityModel> createCity({required String name, required String uf}) async {
    final city = CityModel(id: 'c-${cities.length + 1}', name: name, uf: uf);
    cities.add(city);
    return city;
  }

  @override
  Future<void> updateCity(String id, {String? name, String? uf}) async {
    final i = cities.indexWhere((c) => c.id == id);
    if (i != -1) cities[i] = cities[i].copyWith(name: name, uf: uf);
  }

  @override
  Future<void> deleteCity(String id) async => cities.removeWhere((c) => c.id == id);

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
    final arena = _arena('a-${arenas.length + 1}', name, city, uf).copyWith(
      isLive: isLive,
      replayCount: replayCount,
      status: status,
    );
    arenas.add(arena);
    return arena;
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
    final i = arenas.indexWhere((a) => a.id == id);
    if (i != -1) {
      arenas[i] = arenas[i].copyWith(
        name: name,
        city: city,
        uf: uf,
        isLive: isLive,
        replayCount: replayCount,
        status: status,
      );
    }
  }

  @override
  Future<void> deleteArena(String id) async => arenas.removeWhere((a) => a.id == id);

  @override
  Future<bool> cityExists(String name, String uf) async => cities.any(
        (c) =>
            c.name.toLowerCase() == name.toLowerCase() &&
            c.uf.toLowerCase() == uf.toLowerCase(),
      );
}

void main() {
  group('AdminController', () {
    late FakeAdminDataSource fake;
    late AdminController controller;

    setUp(() {
      fake = FakeAdminDataSource()
        ..cities = [const CityModel(id: 'c-1', name: 'Fortaleza', uf: 'CE')]
        ..arenas = [_arena('a-1', 'Arena Beira Mar', 'Fortaleza', 'CE')]
        ..totalUsers = 3
        ..totalReplays = 7;
      controller = AdminController(fake);
    });

    test('estado inicial é vazio e não carregado', () {
      expect(controller.hasLoaded, isFalse);
      expect(controller.arenas, isEmpty);
      expect(controller.cities, isEmpty);
      expect(controller.error, isNull);
    });

    test('load() popula dados e métricas reais', () async {
      await controller.load();
      expect(controller.hasLoaded, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.totalUsers, 3);
      expect(controller.totalReplays, 7);
      expect(controller.totalArenas, 1);
      expect(controller.totalCities, 1);
    });

    test('load() não recarrega de novo sem force', () async {
      await controller.load();
      await controller.load();
      expect(fake.loadCalls, 1);
      await controller.refresh();
      expect(fake.loadCalls, 2);
    });

    test('load() captura erro e mantém hasLoaded falso', () async {
      fake.throwOnLoad = true;
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.hasLoaded, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('addCity cria no datasource e recarrega o cache', () async {
      await controller.load();
      await controller.addCity('Ceres', 'GO');
      expect(controller.totalCities, 2);
      expect(controller.cities.any((c) => c.name == 'Ceres' && c.uf == 'GO'), isTrue);
    });

    test('addArena cria e aparece no cache', () async {
      await controller.load();
      await controller.addArena(name: 'Areia Club', city: 'Ceres', uf: 'GO');
      expect(controller.totalArenas, 2);
      expect(controller.arenas.any((a) => a.name == 'Areia Club'), isTrue);
    });

    test('removeArena exclui e recarrega', () async {
      await controller.load();
      await controller.removeArena('a-1');
      expect(controller.totalArenas, 0);
    });

    test('removeCity exclui e recarrega', () async {
      await controller.load();
      await controller.removeCity('c-1');
      expect(controller.totalCities, 0);
    });

    test('arenasForCity filtra por nome da cidade', () async {
      await controller.load();
      final fortaleza = controller.arenasForCity(
        const CityModel(id: 'c-1', name: 'Fortaleza', uf: 'CE'),
      );
      expect(fortaleza, hasLength(1));
      final recife = controller.arenasForCity(
        const CityModel(id: 'x', name: 'Recife', uf: 'PE'),
      );
      expect(recife, isEmpty);
    });

    test('cityExists delega ao datasource', () async {
      await controller.load();
      expect(await controller.cityExists('Fortaleza', 'CE'), isTrue);
      expect(await controller.cityExists('Natal', 'RN'), isFalse);
    });

    test('notifica listeners durante o load', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.load();
      expect(notifications, greaterThan(0));
    });
  });
}
