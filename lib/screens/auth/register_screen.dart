import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = 'register';
  static const String routePath = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override

  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await authService.signUpClient(
        email: email,
        password: password,
        name: name,
      );

      if (!mounted) return;

      // Quando a confirmação de e-mail está ligada, o signUp NÃO retorna sessão.
      // Nesse caso não chamamos signIn (falharia) nem navegamos.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _error = 'Conta criada! Confirme seu e-mail para poder entrar.';
        });
        return;
      }

      // Sessão ativa (confirmação de e-mail desligada): segue para a home.
      await context.read<UserProvider>().loadProfile();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );
      context.go(HomeShell.routePath);
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
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crie sua conta ReplayGO',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use o formulário abaixo para configurar o seu perfil.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ao criar sua conta você concorda com os termos de uso e receber comunicações importantes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o email.';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'A senha deve ter ao menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondary),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar conta'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Após o cadastro concluímos o login automaticamente. Você poderá acessar novamente pela tela de login do usuário.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
