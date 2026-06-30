import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive.dart';
import '../../models/arena_model.dart';
import '../../models/city_model.dart';
import '../../models/replay_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/city_grouping.dart';
import '../../widgets/arena_carousel_card.dart';
import '../../widgets/arena_list_tile.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/live_badge.dart';
import '../arena/arena_public_screen.dart';
import '../player/replay_player_screen.dart';
import '../profile/profile_screen.dart';

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

Future<List<ArenaModel>> _fetchArenas() async {
  final client = Supabase.instance.client;

  try {
    final response = await client
        .from('arenas')
        .select(
          '''
            id,
            owner_id,
            name,
            city,
            status,
            is_live,
            replay_count,
            created_at,
            updated_at,
            uf
          ''',
        )
        .eq('status', 'active')
        .order('is_live', ascending: false)
        .order('replay_count', ascending: false)
        .order('name');

    final data = response as List<dynamic>;
    return data
        .map(
          (item) => ArenaModel.fromJson(
            Map<String, dynamic>.from(item as Map<String, dynamic>),
          ),
        )
        .toList();
  } on PostgrestException catch (error) {
    throw Exception(error.message);
  }
}

/// Busca as cidades cadastradas pelo admin. Retorna lista vazia em caso de erro
/// (ex.: tabela `cities` ainda não migrada) para não quebrar a home — nesse
/// caso o agrupamento cai no fallback derivado das arenas.
Future<List<CityModel>> _fetchCities() async {
  final client = Supabase.instance.client;
  try {
    final response = await client.from('cities').select('id, name, uf').order('name');
    final data = response as List<dynamic>;
    return data
        .map((item) => CityModel.fromJson(Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  } catch (_) {
    return const <CityModel>[];
  }
}

class _HomeData {
  const _HomeData({required this.arenas, required this.cities});

  final List<ArenaModel> arenas;
  final List<CityModel> cities;
}

Future<_HomeData> _fetchHomeData() async {
  final results = await Future.wait([_fetchArenas(), _fetchCities()]);
  return _HomeData(
    arenas: results[0] as List<ArenaModel>,
    cities: results[1] as List<CityModel>,
  );
}

Future<List<ReplayModel>> _fetchRecentReplays() async {
  final client = Supabase.instance.client;

  try {
    final response = await client
        .from('replays')
        .select(
          '''
            id,
            arena_id,
            court_id,
            owner_id,
            title,
            description,
            duration_seconds,
            recorded_at,
            visibility,
            created_at,
            updated_at,
            arenas:arena_id(name),
            courts:court_id(name)
          ''',
        )
        .eq('visibility', 'public')
        .order('recorded_at', ascending: false)
        .limit(40);

    final data = response as List<dynamic>;
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final arena = map.remove('arenas') as Map<String, dynamic>?;
      if (arena != null) {
        map['arena_name'] = arena['name'];
      }

      final court = map.remove('courts') as Map<String, dynamic>?;
      if (court != null) {
        map['court_name'] = court['name'];
      }

      map['visibility'] ??= 'public';
      map['recorded_at'] ??= map['created_at'] ?? DateTime.now().toIso8601String();
      map['created_at'] ??= DateTime.now().toIso8601String();
      map['updated_at'] ??= map['created_at'];
      map['duration_seconds'] ??= 0;

      return ReplayModel.fromJson(map);
    }).toList();
  } on PostgrestException catch (error) {
    throw Exception(error.message);
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.onRetry, this.message});

  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.mutedGray),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar os dados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Verifique sua conexão e tente novamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.title,
    required this.description,
    this.icon = Icons.beach_access_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mutedGray),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchHomeData();
  }

  Future<void> _refresh() async {
    final data = await _fetchHomeData();
    if (!mounted) return;
    setState(() => _dataFuture = Future.value(data));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final nameParts = userProvider.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Visitante';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HomeLoadingView();
            }

            if (snapshot.hasError) {
              return _HomeErrorView(
                onRetry: _refresh,
                message: 'Não foi possível carregar as arenas.',
              );
            }

            final arenas = snapshot.data?.arenas ?? const <ArenaModel>[];
            final cities = snapshot.data?.cities ?? const <CityModel>[];
            ArenaModel? featured;
            if (arenas.isNotEmpty) {
              featured = arenas.firstWhere(
                (arena) => arena.isLive,
                orElse: () => arenas.first,
              );
            }

            final groups = buildCityGroups(cities, arenas);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                  'Olá, $firstName',
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
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                userProvider.initials,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (featured == null)
                          const _HomeEmptyState(
                            title: 'Nenhuma arena ativa ainda',
                            description: 'Quando arenas forem cadastradas, elas aparecerão aqui.',
                            icon: Icons.stadium_outlined,
                          )
                        else ...[
                          _FeaturedArenaCard(arena: featured),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                if (groups.isEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 120))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        return _CitySection(
                          city: group.city,
                          uf: group.uf,
                          arenas: group.arenas,
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
              ],
            );
          },
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
                const Icon(Icons.videocam_outlined, color: AppColors.primary),
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
  const _CitySection({required this.city, required this.uf, required this.arenas});

  final String city;
  final String uf;
  final List<ArenaModel> arenas;

  String get _label {
    if (uf.isNotEmpty) {
      return '${city.toUpperCase()} - ${uf.toUpperCase()}';
    }
    return city.toUpperCase();
  }

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
                  _label,
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

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  late Future<List<ArenaModel>> _arenasFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _arenasFuture = _fetchArenas();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
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
              child: FutureBuilder<List<ArenaModel>>(
                future: _arenasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _HomeErrorView(onRetry: () async {
                      final arenas = await _fetchArenas();
                      if (!mounted) return;
                      setState(() => _arenasFuture = Future.value(arenas));
                    }, message: 'Não foi possível carregar arenas.');
                  }

                  final arenas = snapshot.data ?? const <ArenaModel>[];
                  final filtered = arenas.where((arena) {
                    if (_query.isEmpty) return true;
                    final haystack = '${arena.name} ${arena.city} ${arena.uf}'.toLowerCase();
                    return haystack.contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const _HomeEmptyState(
                      title: 'Nenhuma arena encontrada',
                      description: 'Tente outro termo de busca ou aguarde novos cadastros.',
                      icon: Icons.search_off_outlined,
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final arena = filtered[index];
                      return ArenaListTile(
                        arena: arena,
                        onTap: () => context.push(
                          ArenaPublicScreen.routePath,
                          extra: ArenaPublicArguments(arenaId: arena.id),
                        ),
                      );
                    },
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

class _ReplaysTab extends StatefulWidget {
  const _ReplaysTab();

  @override
  State<_ReplaysTab> createState() => _ReplaysTabState();
}

class _ReplaysTabState extends State<_ReplaysTab> {
  late Future<List<ReplayModel>> _replaysFuture;

  @override
  void initState() {
    super.initState();
    _replaysFuture = _fetchRecentReplays();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ResponsiveCenter(
        maxWidth: 900,
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<List<ReplayModel>>(
          future: _replaysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _HomeErrorView(onRetry: () async {
                final replays = await _fetchRecentReplays();
                if (!mounted) return;
                setState(() => _replaysFuture = Future.value(replays));
              }, message: 'Não foi possível carregar os replays recentes.');
            }

            final replays = snapshot.data ?? const <ReplayModel>[];
            if (replays.isEmpty) {
              return const _HomeEmptyState(
                title: 'Nenhum replay disponível ainda',
                description: 'Assim que arenas publicarem replays, eles aparecerão aqui.',
                icon: Icons.video_library_outlined,
              );
            }

            return Column(
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
                            arenaName: replay.arenaName ?? 'Arena',
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
            );
          },
        ),
      ),
    );
  }
}
