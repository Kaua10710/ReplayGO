import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/profile_model.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = <_RoleOption>[
      const _RoleOption(
        role: UserRole.user,
        label: 'Usuário',
        icon: Icons.person_outline,
      ),
      const _RoleOption(
        role: UserRole.owner,
        label: 'Proprietário',
        icon: Icons.apartment_outlined,
      ),
      const _RoleOption(
        role: UserRole.admin,
        label: 'Admin',
        icon: Icons.security_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: roles.map((option) {
          final isSelected = option.role == selectedRole;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(46),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option.icon,
                      color: isSelected ? AppColors.text : AppColors.mutedGray,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.text
                            : AppColors.mutedGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.label,
    required this.icon,
  });

  final UserRole role;
  final String label;
  final IconData icon;
}
