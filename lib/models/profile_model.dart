enum UserRole { user, owner, admin }

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.sport,
    this.notifications = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? sport;
  final int notifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String),
      sport: json['sport'] as String?,
      notifications: (json['notifications'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'sport': sport,
      'notifications': notifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static UserRole _roleFromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.user,
    );
  }
}
