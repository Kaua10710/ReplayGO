import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/arena_model.dart';
import 'live_badge.dart';

/// Card compacto usado nos carrosséis por cidade da home do usuário.
class ArenaCarouselCard extends StatelessWidget {
  const ArenaCarouselCard({
    super.key,
    required this.arena,
    this.onTap,
  });

  final ArenaModel arena;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.backgroundDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (arena.isLive)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: LiveBadge(text: 'AO VIVO'),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arena.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.videocam_outlined,
                        size: 16,
                        color: AppColors.mutedGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${arena.replayCount} replays',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
