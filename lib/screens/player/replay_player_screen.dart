import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/replay_model.dart';

class ReplayPlayerArguments {
  const ReplayPlayerArguments({
    required this.arenaName,
    required this.replay,
  });

  final String arenaName;
  final ReplayModel replay;
}

class ReplayPlayerScreen extends StatelessWidget {
  const ReplayPlayerScreen({super.key, this.routeData});

  static const String routeName = 'replay-player';
  static const String routePath = '/replay';

  final Object? routeData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = routeData is ReplayPlayerArguments
        ? routeData as ReplayPlayerArguments
        : const ReplayPlayerArguments(
            arenaName: 'Arena Beira Mar · Quadra 1',
            replay: const ReplayModel(
              title: 'Ponto decisivo',
              courtName: 'Quadra 1',
              duration: '0:42',
              timeAgo: 'há 12 min',
              visibility: ReplayVisibility.public,
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          args.arenaName.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${args.replay.title} · 14:32',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C1200), AppColors.backgroundDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: AppColors.primary,
                      size: 120,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay_10, color: Colors.white70, size: 36),
                      SizedBox(width: 24),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.play_arrow_rounded, size: 48, color: Colors.white),
                      ),
                      SizedBox(width: 24),
                      Icon(Icons.forward_10, color: Colors.white70, size: 36),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('00:42', style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: 0.6,
                            onChanged: (_) {},
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                      ),
                      const Text('01:30', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Salvar na galeria'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.bookmark_outline),
                          label: const Text('Salvar no perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            minimumSize: const Size(double.infinity, 52),
                          ),
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
