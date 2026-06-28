import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../../models/replay_model.dart';
import '../../providers/user_provider.dart';
import '../../screens/player/replay_player_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/stats_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  const ProfileScreen.embed({super.key}) : embedded = true;

  static const String routeName = 'profile';
  static const String routePath = '/profile';

  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileData>? _profileFuture;
  String? _cachedUserId;
  String? _deletingReplayId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.id;

    if (userId.isEmpty) {
      if (_cachedUserId != null || _profileFuture != null) {
        setState(() {
          _cachedUserId = null;
          _profileFuture = null;
        });
      }
      return;
    }

    if (_cachedUserId != userId) {
      setState(() {
        _cachedUserId = userId;
        _profileFuture = _loadProfileData(userId);
      });
    }
  }

  Future<void> _refreshProfile() async {
    final userId = _cachedUserId;
    if (userId == null) {
      return;
    }
    final future = _loadProfileData(userId);
    setState(() {
      _profileFuture = future;
    });
    await future;
  }

  Future<void> _removeSavedReplay(String savedReplayId) async {
    if (_deletingReplayId != null) {
      return;
    }

    setState(() => _deletingReplayId = savedReplayId);
    final client = Supabase.instance.client;

    try {
      await client.from('saved_replays').delete().eq('id', savedReplayId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Replay removido dos favoritos.')),
      );

      await _refreshProfile();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover replay: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingReplayId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.isLoading && !userProvider.hasProfile) {
      return _buildScaffold(
        context,
        const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = userProvider.profile;
    if (profile == null) {
      return _buildScaffold(
        context,
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            _ProfileMessage(
              icon: Icons.person_off_outlined,
              title: 'Perfil não carregado',
              description: 'Entre novamente para visualizar seus dados.',
              onRetry: userProvider.isLoading ? null : _refreshProfile,
            ),
          ],
        ),
      );
    }

    final future = _profileFuture ?? _loadProfileData(profile.id);

    return _buildScaffold(
      context,
      RefreshIndicator(
        onRefresh: _refreshProfile,
        child: FutureBuilder<_ProfileData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
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

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _ProfileMessage(
                    icon: Icons.wifi_off,
                    title: 'Não foi possível carregar',
                    description: 'Verifique sua conexão e tente novamente.',
                    onRetry: _refreshProfile,
                  ),
                ],
              );
            }

            final data = snapshot.data ?? const _ProfileData(savedReplays: [], publicReplaysCount: 0);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: _buildProfileSections(context, profile, userProvider, data),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, Widget child) {
    final wrapped = SafeArea(child: child);
    if (widget.embedded) {
      return wrapped;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: wrapped,
      bottomNavigationBar: ReplayGoBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  List<Widget> _buildProfileSections(
    BuildContext context,
    ProfileModel profile,
    UserProvider userProvider,
    _ProfileData data,
  ) {
    final theme = Theme.of(context);
    final username = profile.email.split('@').first;
    final sportLabel = (profile.sport ?? '').isNotEmpty ? profile.sport! : 'Sem esporte definido';
    final savedReplays = data.savedReplays;
    final activities = savedReplays.take(3).toList();

    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meu Perfil',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username · $sportLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              userProvider.initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                profile.notifications.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        profile.name,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: StatsCard(
              icon: Icons.bookmark_outline,
              value: savedReplays.length.toString(),
              label: 'Favoritos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.play_circle_outline,
              value: data.publicReplaysCount.toString(),
              label: 'Replays públicos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.notifications_active_outlined,
              value: profile.notifications.toString(),
              label: 'Alertas',
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Meus Replays',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: savedReplays.isEmpty ? null : () {},
            child: const Text('Ver todos'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 190,
        child: savedReplays.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 16,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'Você ainda não salvou replays.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: savedReplays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = savedReplays[index];
                  return _SavedReplayCard(
                    item: item,
                    isDeleting: _deletingReplayId == item.id,
                    onDelete: () => _removeSavedReplay(item.id),
                  );
                },
              ),
      ),
      const SizedBox(height: 32),
      Text(
        'Atividade recente',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      if (activities.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            'Salve replays para acompanhar sua atividade.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedGray,
            ),
          ),
        )
      else
        Column(
          children: activities
              .map(
                (item) => _ActivityTile(
                  title: 'Salvou "${item.replay.title}"',
                  subtitle:
                      '${item.replay.arenaName ?? 'Arena'} · ${_formatTimeAgo(item.savedAt)}',
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 80),
    ];
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedReplayCard extends StatelessWidget {
  const _SavedReplayCard({required this.item, required this.onDelete, required this.isDeleting});

  final _SavedReplayItem item;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(
        ReplayPlayerScreen.routePath,
        extra: ReplayPlayerArguments(
          arenaName: item.replay.arenaName ?? 'Arena',
          replay: item.replay,
        ),
      ),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
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
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.replay.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.replay.courtName ?? 'Quadra'} · ${item.replay.timeAgoLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: isDeleting ? null : onDelete,
                      tooltip: 'Remover dos favoritos',
                      icon: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline, color: AppColors.secondary),
                    ),
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

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
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

class _ProfileData {
  const _ProfileData({
    required this.savedReplays,
    required this.publicReplaysCount,
  });

  final List<_SavedReplayItem> savedReplays;
  final int publicReplaysCount;
}

class _SavedReplayItem {
  const _SavedReplayItem({
    required this.id,
    required this.replay,
    required this.savedAt,
  });

  final String id;
  final ReplayModel replay;
  final DateTime savedAt;
}

Future<_ProfileData> _loadProfileData(String userId) async {
  final client = Supabase.instance.client;

  final savedResponse = await client
      .from('saved_replays')
      .select(
        '''
          id,
          created_at,
          replay_id,
          replays:replay_id (
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
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  final savedItems = <_SavedReplayItem>[];
  for (final item in savedResponse as List<dynamic>) {
    final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
    final replayMap = map.remove('replays') as Map<String, dynamic>?;
    if (replayMap == null) {
      continue;
    }
    final normalized = _normalizeReplayMap(replayMap);
    final replay = ReplayModel.fromJson(normalized);
    savedItems.add(
      _SavedReplayItem(
        id: map['id'] as String,
        replay: replay,
        savedAt: DateTime.parse(map['created_at'] as String),
      ),
    );
  }

  final publicResponse = await client
      .from('replays')
      .select('id')
      .eq('visibility', 'public');

  final publicReplaysCount = (publicResponse as List<dynamic>).length;

  return _ProfileData(
    savedReplays: savedItems,
    publicReplaysCount: publicReplaysCount,
  );
}

Map<String, dynamic> _normalizeReplayMap(Map<String, dynamic> map) {
  final normalized = Map<String, dynamic>.from(map);
  final arena = normalized.remove('arenas') as Map<String, dynamic>?;
  if (arena != null) {
    normalized['arena_name'] = arena['name'];
  }
  final court = normalized.remove('courts') as Map<String, dynamic>?;
  if (court != null) {
    normalized['court_name'] = court['name'];
  }

  normalized['visibility'] ??= 'public';
  normalized['recorded_at'] ??=
      normalized['created_at'] ?? DateTime.now().toIso8601String();
  normalized['created_at'] ??= DateTime.now().toIso8601String();
  normalized['updated_at'] ??= normalized['created_at'];
  normalized['duration_seconds'] ??= 0;

  return normalized;
}

String _formatTimeAgo(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'agora';
  }
  if (difference.inMinutes < 60) {
    return 'há ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'há ${difference.inHours} h';
  }
  if (difference.inDays < 7) {
    return 'há ${difference.inDays} dias';
  }
  final day = timestamp.day.toString().padLeft(2, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final year = timestamp.year;
  return '$day/$month/$year';
}
