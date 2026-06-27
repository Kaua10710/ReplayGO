import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive.dart';
import '../../models/arena_model.dart';
import '../../models/city_model.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../services/mock_service.dart';
import '../../widgets/arena_carousel_card.dart';
import '../../widgets/arena_list_tile.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/live_badge.dart';
import '../arena/arena_public_screen.dart';
import '../profile/profile_screen.dart';
import '../player/replay_player_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const String routeName = 'home-shell';
  static const String routePath = '/home';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeDashboard(),
      const _SearchTab(),
      const _ReplaysTab(),
      const ProfileScreen.embed(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: ReplayGoBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<MockService>();
    final user = service.getProfile(UserRole.user);
    final arenas = service.arenas;
    final featured = arenas.firstWhere((arena) => arena.isLive, orElse: () => arenas.first);

    return SafeArea(
      child: ResponsiveCenter(
        maxWidth: 760,
        child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user.name.split(' ').first}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confira o que está rolando na areia',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedGray,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.notifications.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _FeaturedArenaCard(arena: featured),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: service.cities.length,
            itemBuilder: (context, index) {
              final city = service.cities[index];
              return _CitySection(
                city: city,
                arenas: service.arenasForCity(city),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
        ),
      ),
    );
  }
}

class _FeaturedArenaCard extends StatelessWidget {
  const _FeaturedArenaCard({required this.arena});

  final ArenaModel arena;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(
        ArenaPublicScreen.routePath,
        extra: ArenaPublicArguments(arenaId: arena.id),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  arena.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                if (arena.isLive) const LiveBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              arena.city,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedGray,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
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
                    size: 72,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.videocam_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${arena.replayCount} replays disponíveis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

class _CitySection extends StatelessWidget {
  const _CitySection({required this.city, required this.arenas});

  final CityModel city;
  final List<ArenaModel> arenas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  city.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${arenas.length} ${arenas.length == 1 ? 'quadra' : 'quadras'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (arenas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhuma quadra cadastrada nesta cidade ainda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: arenas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final arena = arenas[index];
                return ArenaCarouselCard(
                  arena: arena,
                  onTap: () => context.push(
                    ArenaPublicScreen.routePath,
                    extra: ArenaPublicArguments(arenaId: arena.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arenas = context.watch<MockService>().arenas;

    return SafeArea(
      child: ResponsiveCenter(
        maxWidth: 760,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buscar quadras',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por arena, cidade ou replay...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: arenas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final arena = arenas[index];
                  return ArenaListTile(
                    arena: arena,
                    onTap: () => context.push(
                      ArenaPublicScreen.routePath,
                      extra: ArenaPublicArguments(arenaId: arena.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplaysTab extends StatelessWidget {
  const _ReplaysTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arena = context.watch<MockService>().arenas.first;
    final replays = arena.replays;

    return SafeArea(
      child: ResponsiveCenter(
        maxWidth: 900,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replays recentes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: context.isMobile ? 220 : 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: replays.length,
                itemBuilder: (context, index) {
                  final replay = replays[index];
                  return GestureDetector(
                    onTap: () => context.push(
                      ReplayPlayerScreen.routePath,
                      extra: ReplayPlayerArguments(
                        arenaName: arena.name,
                        replay: replay,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [AppColors.backgroundDark, AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          replay.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${replay.courtName ?? 'Quadra'} · ${replay.timeAgoLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
