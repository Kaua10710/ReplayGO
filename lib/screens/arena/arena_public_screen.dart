import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/arena_model.dart';
import '../../models/court_model.dart';
import '../../models/replay_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/supabase_replay_mapper.dart';
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
  Future<_ArenaPublicData>? _arenaFuture;
  String? _currentArenaId;
  String? _selectedCourtId;
  String? _initialCourtId;
  final Set<String> _savingReplayIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = widget.routeData is ArenaPublicArguments
        ? widget.routeData as ArenaPublicArguments
        : null;

    final arenaId = args?.arenaId;
    if (_initialCourtId == null) {
      _initialCourtId = args?.initialCourt;
    }

    if (_arenaFuture == null || _currentArenaId != arenaId) {
      _arenaFuture = _loadArenaData(arenaId);
      _currentArenaId = arenaId;
    }
  }

  Future<void> _refresh() async {
    final future = _loadArenaData(_currentArenaId);
    setState(() {
      _arenaFuture = future;
    });
    await future;
  }

  Future<_ArenaPublicData> _loadArenaData(String? arenaId) async {
    final client = Supabase.instance.client;

    try {
      var query = client
          .from('arenas')
          .select(
            '''
              id,
              owner_id,
              name,
              city,
              uf,
              status,
              is_live,
              replay_count,
              created_at,
              updated_at,
              courts (*),
              replays (
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
              )
            ''',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false);

      if (arenaId != null && arenaId.isNotEmpty) {
        query = query.eq('id', arenaId);
      }

      final response = await query.limit(1);
      final list = response as List<dynamic>;
      if (list.isEmpty) {
        throw Exception('Arena não encontrada.');
      }

      final map = Map<String, dynamic>.from(list.first as Map<String, dynamic>);
      map['courts'] = (map['courts'] as List<dynamic>? ?? [])
          .map((court) => Map<String, dynamic>.from(court as Map<String, dynamic>))
          .toList();
      map['replays'] = (map['replays'] as List<dynamic>? ?? [])
          .map((replay) => normalizeReplayRow(Map<String, dynamic>.from(replay as Map<String, dynamic>)))
          .toList();

      final arena = ArenaModel.fromJson(map);
      return _ArenaPublicData(
        arena: arena,
        courts: arena.courts,
        replays: arena.replays,
      );
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<void> _handleSaveReplay(ReplayModel replay) async {
    if (_savingReplayIds.contains(replay.id)) {
      return;
    }

    final userId = context.read<UserProvider>().id;
    if (userId.isEmpty) {
      _showSnack('Entre para salvar replays.', isError: true);
      return;
    }

    setState(() => _savingReplayIds.add(replay.id));
    final client = Supabase.instance.client;

    try {
      await client.from('saved_replays').upsert({
            'replay_id': replay.id,
            'user_id': userId,
          });
      _showSnack('Replay salvo no seu perfil.');
    } on PostgrestException catch (error) {
      _showSnack(error.message, isError: true);
    } catch (_) {
      _showSnack('Não foi possível salvar o replay.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingReplayIds.remove(replay.id));
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.secondary : AppColors.primary,
        ),
      );
  }

  CourtModel _defaultCourt(ArenaModel arena) {
    return CourtModel(
      id: 'default-${arena.id}',
      arenaId: arena.id,
      name: 'Quadra principal',
      isLive: arena.isLive,
      createdAt: arena.createdAt,
      updatedAt: arena.updatedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _arenaFuture;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: future == null
            ? const _ArenaLoadingView()
            : RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<_ArenaPublicData>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                      return const _ArenaLoadingView();
                    }

                    if (snapshot.hasError) {
                      return _ArenaMessageList(
                        child: _ArenaMessageView(
                          icon: Icons.wifi_off,
                          title: 'Não foi possível carregar a arena',
                          description: 'Verifique sua conexão e tente novamente.',
                          onRetry: _refresh,
                        ),
                      );
                    }

                    final data = snapshot.data;
                    if (data == null) {
                      return _ArenaMessageList(
                        child: _ArenaMessageView(
                          icon: Icons.stadium_outlined,
                          title: 'Arena não encontrada',
                          description: 'A arena selecionada pode ter sido removida.',
                          onRetry: _refresh,
                        ),
                      );
                    }

                    return _buildLoadedView(data);
                  },
                ),
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

  Widget _buildLoadedView(_ArenaPublicData data) {
    final arena = data.arena;

    var courts = data.courts;
    if (courts.isEmpty) {
      courts = [_defaultCourt(arena)];
    }

    String? desiredCourtId = _selectedCourtId ?? _initialCourtId;
    if (desiredCourtId != null && !courts.any((court) => court.id == desiredCourtId)) {
      desiredCourtId = courts.first.id;
    }
    desiredCourtId ??= courts.isNotEmpty ? courts.first.id : null;

    final CourtModel? selectedCourt;
    if (desiredCourtId != null) {
      selectedCourt = courts.firstWhere(
        (court) => court.id == desiredCourtId,
        orElse: () => courts.first,
      );
    } else {
      selectedCourt = courts.isNotEmpty ? courts.first : null;
    }

    if (_selectedCourtId != desiredCourtId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCourtId = desiredCourtId;
          _initialCourtId = null;
        });
      });
    }

    if (_currentArenaId != arena.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _currentArenaId = arena.id;
      });
    }

    final filteredReplays = data.replays.where((replay) {
      if (desiredCourtId == null) {
        return true;
      }
      return replay.courtId == null || replay.courtId == desiredCourtId;
    }).toList();

    final locationLabel = arena.uf.isNotEmpty ? '${arena.city} · ${arena.uf.toUpperCase()}' : arena.city;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                    Expanded(
                      child: Text(
                        arena.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (arena.isLive) const LiveBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.mutedGray),
                    const SizedBox(width: 4),
                    Text(
                      locationLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedGray,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _VideoPlayerPlaceholder(
                  courtName: selectedCourt?.name ?? 'Quadra',
                  isLive: arena.isLive,
                ),
                const SizedBox(height: 16),
                if (courts.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: courts.map((court) {
                        final isSelected = court.id == desiredCourtId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(court.name),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedCourtId = court.id);
                            },
                            selectedColor: AppColors.text,
                            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: isSelected ? Colors.white : AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (courts.length <= 1) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      selectedCourt?.name ?? 'Quadra principal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Replays · últimas 72h',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        if (filteredReplays.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ArenaMessageCard(
                icon: Icons.play_disabled_outlined,
                title: 'Nenhum replay para esta quadra',
                description: 'Assim que novos lances forem publicados, eles aparecerão aqui.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final replay = filteredReplays[index];
                  final isSaving = _savingReplayIds.contains(replay.id);
                  return GestureDetector(
                    onTap: () => context.push(
                      ReplayPlayerScreen.routePath,
                      extra: ReplayPlayerArguments(
                        arenaName: arena.name,
                        replay: replay,
                      ),
                    ),
                    child: ReplayCard(
                      replay: replay,
                      onSave: isSaving ? null : () => _handleSaveReplay(replay),
                    ),
                  );
                },
                childCount: filteredReplays.length,
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
    );
  }
}

class _ArenaPublicData {
  const _ArenaPublicData({
    required this.arena,
    required this.courts,
    required this.replays,
  });

  final ArenaModel arena;
  final List<CourtModel> courts;
  final List<ReplayModel> replays;
}

class _ArenaLoadingView extends StatelessWidget {
  const _ArenaLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ArenaMessageList extends StatelessWidget {
  const _ArenaMessageList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        child,
      ],
    );
  }
}

class _ArenaMessageView extends StatelessWidget {
  const _ArenaMessageView({
    required this.icon,
    required this.title,
    required this.description,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String description;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: AppColors.mutedGray),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => onRetry!(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}

class _ArenaMessageCard extends StatelessWidget {
  const _ArenaMessageCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
            blurRadius: 16,
            offset: Offset(0, 12),
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerPlaceholder extends StatelessWidget {
  const _VideoPlayerPlaceholder({required this.courtName, required this.isLive});

  final String courtName;
  final bool isLive;

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
        if (isLive)
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
                    'AO VIVO',
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
              color: Colors.black.withValues(alpha: 0.5),
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
