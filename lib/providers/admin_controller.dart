import 'package:flutter/foundation.dart';

import '../models/arena_model.dart';
import '../models/city_model.dart';
import '../services/admin_service.dart';

/// Camada reativa do painel administrativo.
///
/// Encapsula o [AdminService] (Supabase), mantém em cache as listas de arenas e
/// cidades + métricas do dashboard e expõe operações CRUD assíncronas que
/// recarregam os dados automaticamente. A UI do admin observa este controller,
/// então qualquer cadastro/edição/exclusão reflete imediatamente na tela.
class AdminController extends ChangeNotifier {
  AdminController(this._service);

  final AdminDataSource _service;

  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _error;
  List<ArenaModel> _arenas = const [];
  List<CityModel> _cities = const [];
  int _totalUsers = 0;
  int _totalReplays = 0;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  Object? get error => _error;
  List<ArenaModel> get arenas => List.unmodifiable(_arenas);
  List<CityModel> get cities => List.unmodifiable(_cities);
  int get totalUsers => _totalUsers;
  int get totalReplays => _totalReplays;
  int get totalArenas => _arenas.length;
  int get totalCities => _cities.length;

  /// Carrega o dashboard. Use [force] para recarregar mesmo já tendo dados.
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.loadDashboard();
      _arenas = data.arenas;
      _cities = data.cities;
      _totalUsers = data.totalUsers;
      _totalReplays = data.totalReplays;
      _hasLoaded = true;
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);

  List<ArenaModel> arenasForCity(CityModel city) {
    final target = city.name.trim().toLowerCase();
    return _arenas
        .where((arena) => arena.city.trim().toLowerCase() == target)
        .toList();
  }

  Future<bool> cityExists(String name, String uf) =>
      _service.cityExists(name, uf);

  // --- Cidades ---------------------------------------------------------------

  Future<void> addCity(String name, String uf) async {
    await _service.createCity(name: name, uf: uf);
    await refresh();
  }

  Future<void> updateCity(String id, {String? name, String? uf}) async {
    await _service.updateCity(id, name: name, uf: uf);
    await refresh();
  }

  Future<void> removeCity(String id) async {
    await _service.deleteCity(id);
    await refresh();
  }

  // --- Arenas ----------------------------------------------------------------

  Future<void> addArena({
    required String name,
    required String city,
    required String uf,
    bool isLive = false,
    int replayCount = 0,
    ArenaStatus status = ArenaStatus.active,
    String? ownerId,
  }) async {
    await _service.createArena(
      name: name,
      city: city,
      uf: uf,
      isLive: isLive,
      replayCount: replayCount,
      status: status,
      ownerId: ownerId,
    );
    await refresh();
  }

  Future<void> updateArena(
    String id, {
    String? name,
    String? city,
    String? uf,
    bool? isLive,
    int? replayCount,
    ArenaStatus? status,
  }) async {
    await _service.updateArena(
      id,
      name: name,
      city: city,
      uf: uf,
      isLive: isLive,
      replayCount: replayCount,
      status: status,
    );
    await refresh();
  }

  Future<void> removeArena(String id) async {
    await _service.deleteArena(id);
    await refresh();
  }
}
