import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/replay_model.dart';

class ReplayCard extends StatelessWidget {
  const ReplayCard({
    super.key,
    required this.replay,
    this.onTap,
    this.onSave,
    this.onShare,
  });

  final ReplayModel replay;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  Color _badgeColor() {
    switch (replay.visibility) {
      case ReplayVisibility.public:
        return AppColors.primary;
      case ReplayVisibility.expired:
        return AppColors.mutedGray;
    }
  }

  String _badgeLabel() {
    switch (replay.visibility) {
      case ReplayVisibility.public:
        return 'PÚBLICO';
      case ReplayVisibility.expired:
        return 'EXPIRADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        replay.duration,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor().withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _badgeLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              replay.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${replay.courtName} · ${replay.timeAgo}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedGray,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: onShare,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.lightGray,
                    ),
                    child: const Icon(Icons.ios_share),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
