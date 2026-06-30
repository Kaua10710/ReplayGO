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
    // O perfil é criado pelo trigger `handle_new_user` no banco a partir dos
    // metadados (name/role). Não fazemos upsert em `profiles` aqui: além de
    // redundante, falharia sob RLS (não há policy de INSERT para o próprio
    // usuário).
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

  /// Envia um email de redefinição de senha para o endereço informado.
  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

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

  Future<List<ProfileModel>> fetchProfilesByRole(UserRole role) async {
    final List<dynamic> response = await _client
        .from('profiles')
        .select('*')
        .eq('role', role.name)
        .order('created_at');

    return response
        .whereType<Map<String, dynamic>>()
        .map(ProfileModel.fromJson)
        .toList();
  }
}

/// Converte erros de autenticação do Supabase em mensagens claras em PT-BR.
String authErrorMessagePt(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (message.contains('password should be at least')) {
      return 'A senha é muito curta.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Muitas tentativas. Aguarde um instante e tente de novo.';
    }
    // Fallback: usa a mensagem original quando não há tradução conhecida.
    return error.message;
  }
  return 'Algo deu errado. Tente novamente.';
}
