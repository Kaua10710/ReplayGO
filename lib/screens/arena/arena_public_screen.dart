import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/arena_model.dart';
import '../../models/court_model.dart';
import '../../models/replay_model.dart';
import '../../services/mock_service.dart';
import '../../widgets/replay_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/live_badge.dart';
import '../player/replay_player_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class ArenaPublicArguments {
  const ArenaPublicArguments({required this.arenaId, this.initialCourt});

  final String arenaId;
  final String? initialCourt;
}

class ArenaPublicScreen extends StatefulWidget {
  const ArenaPublicScreen({super.key, this.routeData});

  static const String routeName = 'arena-public';
  static const String routePath = '/arena';

  final Object? routeData;

  @override
  State<ArenaPublicScreen> createState() => _ArenaPublicScreenState();
}

class _ArenaPublicScreenState extends State<ArenaPublicScreen> {
  late ArenaModel _arena;
  late List<CourtModel> _courts;
  late List<ReplayModel> _replays;
  int _selectedCourtIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<MockService>();
    final args = widget.routeData is ArenaPublicArguments
        ? widget.routeData as ArenaPublicArguments
        : ArenaPublicArguments(arenaId: service.arenas.first.id);
    _arena = service.getArenaById(args.arenaId);
    _courts = _arena.courts.isEmpty
        ? const [
            CourtModel(id: 'default', name: 'Quadra 1', isLive: true),
          ]
        : _arena.courts;
    _replays = _arena.replays;

    if (args.initialCourt != null) {
      final idx = _courts.indexWhere((court) => court.id == args.initialCourt);
      if (idx != -1) {
        _selectedCourtIndex = idx;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _arena.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_arena.isLive) const LiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.mutedGray),
                        const SizedBox(width: 4),
                        Text(
                          _arena.city,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _VideoPlayerPlaceholder(
                      courtName: _courts[_selectedCourtIndex].name,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_courts.length, (index) {
                          final court = _courts[index];
                          final isSelected = index == _selectedCourtIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text(court.name),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCourtIndex = index),
                              selectedColor: AppColors.text,
                              labelStyle: theme.textTheme.labelLarge?.copyWith(
                                color: isSelected ? Colors.white : AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Replays · últimas 72h',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Ver tudo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final replay = _replays[index];
                    return ReplayCard(
                      replay: replay,
                      onSave: () {},
                      onShare: () {},
                    );
                  },
                  childCount: _replays.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
      bottomNavigationBar: ReplayGoBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(HomeShell.routePath);
              break;
            case 3:
              context.push(ProfileScreen.routePath);
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}

class _VideoPlayerPlaceholder extends StatelessWidget {
  const _VideoPlayerPlaceholder({required this.courtName});

  final String courtName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.backgroundDark, Color(0xFF3C1B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              courtName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
