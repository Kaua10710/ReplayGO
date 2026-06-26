import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/arena_model.dart';
import '../widgets/live_badge.dart';

class ArenaListTile extends StatelessWidget {
  const ArenaListTile({
    super.key,
    required this.arena,
    this.onTap,
    this.onMorePressed,
  });

  final ArenaModel arena;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;

  Color _statusColor(ArenaStatus status) {
    switch (status) {
      case ArenaStatus.active:
        return AppColors.primary;
      case ArenaStatus.inactive:
        return AppColors.mutedGray;
    }
  }

  String _statusLabel(ArenaStatus status) {
    switch (status) {
      case ArenaStatus.active:
        return 'ATIVO';
      case ArenaStatus.inactive:
        return 'INATIVO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                radius: 28,
                child: Text(
                  arena.name
                      .split(' ')
                      .take(2)
                      .map((word) => word[0])
                      .join()
                      .toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            arena.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (arena.isLive) const LiveBadge(text: 'LIVE'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${arena.city} · ${arena.replayCount} replays',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(arena.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(arena.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMorePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
