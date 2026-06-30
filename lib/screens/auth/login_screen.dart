import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../providers/user_provider.dart';
import '../../screens/admin/admin_panel_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/owner/owner_dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_selector.dart';
import '../splash/splash_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _MockCredential {
  const _MockCredential({required this.email, required this.password});

  final String email;
  final String password;
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _useMockCredentials = false;
  String? _error;

  static const Map<UserRole, _MockCredential> _mockProfiles = {
    UserRole.user: _MockCredential(
      email: 'lucas@replaygo.com',
      password: 'Test@1234',
    ),
    UserRole.owner: _MockCredential(
      email: 'arena@replaygo.com',
      password: 'Test@1234',
    ),
    UserRole.admin: _MockCredential(
      email: 'admin@replaygo.com',
      password: 'Test@1234',
    ),
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.owner => 'estabelecimento',
        UserRole.admin => 'administrador',
        UserRole.user => 'usuário',
      };

  void _applyMockCredentials(UserRole role) {
    final credential = _mockProfiles[role];
    if (credential == null) {
      return;
    }

    _emailController.value = TextEditingValue(
      text: credential.email,
      selection: TextSelection.collapsed(offset: credential.email.length),
    );
    _passwordController.value = TextEditingValue(
      text: credential.password,
      selection: TextSelection.collapsed(offset: credential.password.length),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe seu email no campo acima para redefinir a senha.');
      return;
    }

    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await authService.resetPassword(email);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Enviamos um link de redefinição para $email.')),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível enviar o email de redefinição.');
    }
  }

  Future<void> _handleLogin() async {
    final authService = context.read<AuthService>();
    final userProvider = context.read<UserProvider>();
    final router = GoRouter.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final role = await authService.signIn(email: email, password: password);

      if (!mounted) {
        return;
      }

      await userProvider.loadProfile();

      switch (role) {
        case UserRole.owner:
          router.go(OwnerDashboardScreen.routePath);
          break;
        case UserRole.admin:
          router.go(AdminPanelScreen.routePath);
          break;
        case UserRole.user:
          router.go(HomeShell.routePath);
          break;
      }
    } on AuthException catch (error) {
      setState(() => _error = authErrorMessagePt(error));
    } catch (error) {
      setState(() => _error = authErrorMessagePt(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(SplashScreen.routePath),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ReplayGO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Bem-vindo de volta.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre para rever os melhores momentos das quadras.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
              const SizedBox(height: 24),
              RoleSelector(
                selectedRole: _selectedRole,
                onChanged: (UserRole role) {
                  setState(() => _selectedRole = role);
                  if (_useMockCredentials) {
                    _applyMockCredentials(role);
                  }
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'nome@email.com',
                  prefixIcon: const Icon(Icons.mail_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _useMockCredentials,
                onChanged: (value) {
                  final enabled = value ?? false;
                  setState(() => _useMockCredentials = enabled);
                  if (enabled) {
                    _applyMockCredentials(_selectedRole);
                  } else {
                    _emailController.clear();
                    _passwordController.clear();
                  }
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Preencher automaticamente com dados de teste',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: Text(
                    'Esqueci minha senha',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondary),
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Entrar como ${_roleLabel(_selectedRole)}'),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.push(RegisterScreen.routePath),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: const [
                        TextSpan(text: 'Não tem conta? '),
                        TextSpan(
                          text: 'Criar conta',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
