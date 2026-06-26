enum UserRole { user, owner, admin }

class UserModel {
  const UserModel({
    required this.name,
    required this.username,
    required this.sport,
    required this.replaysSaved,
    required this.role,
    this.notifications = 0,
  });

  final String name;
  final String username;
  final String sport;
  final int replaysSaved;
  final UserRole role;
  final int notifications;
}
