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
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
      },
    );

    final user = response.user;
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'name': name,
        'role': role.name,
        'notifications': 0,
      });
    }

    return response;
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

  Future<AuthResponse> signUpOwner({
    required String email,
    required String password,
    required String name,
  }) {
    return signUp(
      email: email,
      password: password,
      name: name,
      role: UserRole.owner,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserRole?> getCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final roleValue = response['role'] as String?;
    if (roleValue == null) {
      return null;
    }

    return UserRole.values.firstWhere(
      (role) => role.name == roleValue,
      orElse: () => UserRole.user,
    );
  }

  Future<List<ProfileModel>> fetchProfilesByRole(UserRole role) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('role', role.name)
        .order('created_at');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ProfileModel.fromJson)
          .toList();
    }

    return const [];
  }
}
