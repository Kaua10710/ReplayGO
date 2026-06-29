import 'package:flutter_test/flutter_test.dart';
import 'package:replaygo/models/arena_model.dart';
import 'package:replaygo/models/city_model.dart';
import 'package:replaygo/utils/city_grouping.dart';

ArenaModel _arena(
  String id,
  String name,
  String city,
  String uf, {
  bool isLive = false,
  int replayCount = 0,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return ArenaModel(
    id: id,
    name: name,
    city: city,
    uf: uf,
    isLive: isLive,
    replayCount: replayCount,
    status: ArenaStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('buildCityGroups', () {
    test('cidade cadastrada sem arenas aparece como seção vazia', () {
      final groups = buildCityGroups(
        const [CityModel(id: 'c1', name: 'Ceres', uf: 'GO')],
        const [],
      );
      expect(groups, hasLength(1));
      expect(groups.first.city, 'Ceres');
      expect(groups.first.arenas, isEmpty);
    });

    test('agrupa arenas sob a cidade cadastrada correspondente', () {
      final groups = buildCityGroups(
        const [CityModel(id: 'c1', name: 'Fortaleza', uf: 'CE')],
        [
          _arena('a1', 'Arena Beira Mar', 'Fortaleza', 'CE'),
          _arena('a2', 'Sand Center', 'Fortaleza', 'CE'),
        ],
      );
      expect(groups, hasLength(1));
      expect(groups.first.arenas, hasLength(2));
    });

    test('arena de cidade não cadastrada vira seção fallback', () {
      final groups = buildCityGroups(
        const [CityModel(id: 'c1', name: 'Fortaleza', uf: 'CE')],
        [_arena('a1', 'Quadra do Zé', 'Recife', 'PE')],
      );
      // Fortaleza (vazia) + Recife (fallback) = 2 seções.
      expect(groups, hasLength(2));
      final recife = groups.firstWhere((g) => g.city == 'Recife');
      expect(recife.arenas, hasLength(1));
    });

    test('arenas ao vivo vêm primeiro dentro da cidade', () {
      final groups = buildCityGroups(
        const [CityModel(id: 'c1', name: 'Fortaleza', uf: 'CE')],
        [
          _arena('a1', 'Sem live', 'Fortaleza', 'CE', replayCount: 50),
          _arena('a2', 'Com live', 'Fortaleza', 'CE', isLive: true, replayCount: 1),
        ],
      );
      expect(groups.first.arenas.first.name, 'Com live');
    });

    test('seções são ordenadas alfabeticamente por cidade', () {
      final groups = buildCityGroups(
        const [
          CityModel(id: 'c1', name: 'Recife', uf: 'PE'),
          CityModel(id: 'c2', name: 'Fortaleza', uf: 'CE'),
        ],
        const [],
      );
      expect(groups.map((g) => g.city).toList(), ['Fortaleza', 'Recife']);
    });

    test('sem cidades cadastradas, usa fallback derivado das arenas', () {
      final groups = buildCityGroups(
        const [],
        [_arena('a1', 'Areia Club', 'Florianópolis', 'SC')],
      );
      expect(groups, hasLength(1));
      expect(groups.first.city, 'Florianópolis');
    });
  });
}
