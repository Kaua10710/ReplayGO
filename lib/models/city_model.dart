class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.uf,
  });

  final String id;
  final String name;
  final String uf;

  /// Rótulo exibido no subtítulo das seções (ex.: "CARMO DO RIO VERDE - GO").
  String get label => '${name.toUpperCase()} - ${uf.toUpperCase()}';

  CityModel copyWith({String? name, String? uf}) {
    return CityModel(
      id: id,
      name: name ?? this.name,
      uf: uf ?? this.uf,
    );
  }
}
