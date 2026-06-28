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

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      uf: (json['uf'] as String? ?? '').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uf': uf,
    };
  }
}
