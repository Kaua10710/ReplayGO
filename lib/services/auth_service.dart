import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class AuthService {
  AuthService();

  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
      },
    );
  }

  Future<AuthResponse> signUpClient({
    required String email,
    required String password,
    required String name,
  }) {
    return signUp(
      email: email,
      password: password,
      name: name,
      role: UserRole.user,
    );
  }

  Future<UserRole> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Credenciais inválidas.');
    }

    final metadataRole = _roleFromMetadata(user.userMetadata);
    if (metadataRole != null) {
      return metadataRole;
    }

    final profileRole = await _fetchRoleFromProfiles(user.id);
    return profileRole ?? UserRole.user;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserRole> getCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return UserRole.user;
    }

    final metadataRole = _roleFromMetadata(user.userMetadata);
    if (metadataRole != null) {
      return metadataRole;
    }

    final profileRole = await _fetchRoleFromProfiles(user.id);
    return profileRole ?? UserRole.user;
  }

  Future<UserRole?> _fetchRoleFromProfiles(String userId) async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    final roleValue = response?['role'] as String?;
    if (roleValue == null) {
      return null;
    }

    return _roleFromString(roleValue);
  }

  UserRole? _roleFromMetadata(Map<String, dynamic>? metadata) {
    final roleValue = metadata?['role'] as String?;
    if (roleValue == null) {
      return null;
    }
    return _roleFromString(roleValue);
  }

  UserRole _roleFromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.user,
    );
  }
}
