import '../models/arena_model.dart';
import '../models/city_model.dart';

/// Uma seção da home: uma cidade e suas arenas (pode ser vazia).
class CityGroup {
  const CityGroup({
    required this.city,
    required this.uf,
    required this.arenas,
  });

  final String city;
  final String uf;
  final List<ArenaModel> arenas;
}

void _sortArenas(List<ArenaModel> arenas) {
  arenas.sort((a, b) {
    if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
    if (a.replayCount != b.replayCount) {
      return b.replayCount.compareTo(a.replayCount);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

/// Agrupa arenas por cidade quando não há lista de cidades cadastradas
/// (fallback derivado apenas das arenas).
List<CityGroup> groupArenasByCity(List<ArenaModel> arenas) {
  if (arenas.isEmpty) return const [];

  final Map<String, List<ArenaModel>> groups = {};
  for (final arena in arenas) {
    final key = arena.city.trim().toLowerCase();
    groups.putIfAbsent(key, () => <ArenaModel>[]).add(arena);
  }

  return groups.values.map((list) {
    _sortArenas(list);
    final representative = list.first;
    return CityGroup(
      city: representative.city,
      uf: representative.uf,
      arenas: list,
    );
  }).toList()
    ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
}

/// Monta as seções da home a partir das cidades cadastradas (que aparecem mesmo
/// sem arenas) e das arenas. Arenas cuja cidade não está cadastrada também
/// ganham uma seção (fallback), garantindo que nenhuma arena fique escondida.
List<CityGroup> buildCityGroups(List<CityModel> cities, List<ArenaModel> arenas) {
  if (cities.isEmpty) {
    return groupArenasByCity(arenas);
  }

  final Map<String, List<ArenaModel>> byCity = {};
  for (final arena in arenas) {
    byCity.putIfAbsent(arena.city.trim().toLowerCase(), () => <ArenaModel>[]).add(arena);
  }

  final Map<String, CityGroup> result = {};

  // Cidades cadastradas primeiro (aparecem mesmo sem arenas).
  for (final city in cities) {
    final key = city.name.trim().toLowerCase();
    final list = byCity[key] ?? <ArenaModel>[];
    _sortArenas(list);
    result[key] = CityGroup(city: city.name, uf: city.uf, arenas: list);
  }

  // Arenas em cidades não cadastradas (fallback).
  byCity.forEach((key, list) {
    if (!result.containsKey(key)) {
      _sortArenas(list);
      final rep = list.first;
      result[key] = CityGroup(city: rep.city, uf: rep.uf, arenas: list);
    }
  });

  return result.values.toList()
    ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
}
