import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const String routeName = 'register';
  static const String routePath = '/register';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estamos em construção!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No MVP, a criação de conta está sendo configurada. Volte em breve.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
