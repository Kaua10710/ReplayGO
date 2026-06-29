import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/arena_model.dart';
import '../../models/court_model.dart';
import '../../models/replay_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/supabase_replay_mapper.dart';
import '../../widgets/replay_share_sheet.dart';
import '../../widgets/stats_card.dart';
import '../player/replay_player_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  static const String routeName = 'owner-dashboard';
  static const String routePath = '/owner';

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboardScreen> {
  Future<List<ArenaModel>>? _arenasFuture;
  String? _cachedOwnerId;
  String? _selectedArenaId;
  bool _isUpdatingLive = false;
  final Map<String, bool> _pendingLiveOverride = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ownerId = Provider.of<UserProvider>(context).id;

    if (ownerId.isEmpty) {
      if (_cachedOwnerId != null) {
        setState(() {
          _cachedOwnerId = null;
          _arenasFuture = null;
          _selectedArenaId = null;
          _pendingLiveOverride.clear();
        });
      }
      return;
    }

    if (_cachedOwnerId != ownerId) {
      _loadDataForOwner(ownerId);
    }
  }

  void _loadDataForOwner(String ownerId) {
    final future = _loadOwnerArenas(ownerId);
    setState(() {
      _cachedOwnerId = ownerId;
      _arenasFuture = future;
      _selectedArenaId = null;
      _pendingLiveOverride.clear();
    });

    future.then((arenas) {
      if (!mounted) return;
      setState(() {
        _selectedArenaId = arenas.isNotEmpty ? arenas.first.id : null;
      });
    });
  }

  Future<void> _refresh() async {
    final ownerId = _cachedOwnerId;
    if (ownerId == null) return;

    final future = _loadOwnerArenas(ownerId);
    setState(() {
      _arenasFuture = future;
      _pendingLiveOverride.clear();
    });

    final arenas = await future;
    if (!mounted) return;
    setState(() {
      if (arenas.isEmpty) {
        _selectedArenaId = null;
      } else if (_selectedArenaId == null || !arenas.any((arena) => arena.id == _selectedArenaId)) {
        _selectedArenaId = arenas.first.id;
      }
    });
  }

  Future<void> _updateLiveStatus(ArenaModel arena, bool value) async {
    if (_isUpdatingLive) return;

    setState(() {
      _isUpdatingLive = true;
      _pendingLiveOverride[arena.id] = value;
    });

    final client = Supabase.instance.client;
    try {
      await client.from('arenas').update({'is_live': value}).eq('id', arena.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Arena marcada como ao vivo.' : 'Arena marcada como offline.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível atualizar o status: $error'),
        ),
      );
      setState(() {
        _pendingLiveOverride.remove(arena.id);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLive = false;
        });
        await _refresh();
      }
    }
  }

  Future<void> _handleShareReplay(ReplayModel replay) async {
    if (!mounted) return;
    final message = await showReplayShareSheet(context, replay);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
        ),
      );
  }

  String _statusLabel(ArenaStatus status) {
    switch (status) {
      case ArenaStatus.active:
        return 'Ativa';
      case ArenaStatus.inactive:
        return 'Inativa';
    }
  }

  Future<bool> _updateArenaStatus(ArenaModel arena, ArenaStatus status) async {
    final client = Supabase.instance.client;

    try {
      await client.from('arenas').update({'status': status.name}).eq('id', arena.id);
      if (!mounted) {
        return true;
      }
      final message = status == ArenaStatus.active
          ? 'Arena reativada. Clientes voltam a visualizar os replays.'
          : 'Arena marcada como inativa. Ela fica oculta para clientes.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primary,
          ),
        );
      return true;
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar status: ${error.message}'),
              backgroundColor: AppColors.secondary,
            ),
          );
      }
      return false;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível alterar o status da arena.'),
              backgroundColor: AppColors.secondary,
            ),
          );
      }
      return false;
    }
  }

  Future<bool> _updateCourtLiveStatus(CourtModel court, bool value) async {
    final client = Supabase.instance.client;

    try {
      await client.from('courts').update({'is_live': value}).eq('id', court.id);
      if (mounted) {
        final message = value
            ? '"${court.name}" ficará visível para os clientes.'
            : '"${court.name}" foi ocultada do app.';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.primary,
            ),
          );
      }
      return true;
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar a quadra: ${error.message}'),
              backgroundColor: AppColors.secondary,
            ),
          );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível atualizar a quadra.'),
              backgroundColor: AppColors.secondary,
            ),
          );
      }
      return false;
    }
  }

  Future<void> _copyArenaLink(ArenaModel arena) async {
    final link = 'https://replaygo.app/arenas/${arena.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Link da arena copiado para a área de transferência.'),
          backgroundColor: AppColors.primary,
        ),
      );
  }

  Future<void> _openAdvancedControls(ArenaModel arena) async {
    if (!mounted) return;

    var shouldRefresh = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final overrides = <String, bool>{
          for (final court in arena.courts) court.id: court.isLive,
        };
        final busyCourts = <String>{};
        var localStatus = arena.status;
        var busyArena = false;

        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Controles avançados',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      arena.name,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Status da arena',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: ArenaStatus.values.map((status) {
                        final selected = localStatus == status;
                        return ChoiceChip(
                          label: Text(_statusLabel(status)),
                          selected: selected,
                          onSelected: (!selected && !busyArena)
                              ? (value) async {
                                  if (!value) return;
                                  sheetSetState(() => busyArena = true);
                                  final success = await _updateArenaStatus(arena, status);
                                  if (!mounted) return;
                                  sheetSetState(() {
                                    busyArena = false;
                                    if (success) {
                                      localStatus = status;
                                      shouldRefresh = true;
                                    }
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                    if (busyArena)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Quadras com câmeras',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (arena.courts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Nenhuma quadra vinculada a esta arena.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
                        ),
                      )
                    else
                      Column(
                        children: arena.courts.map((court) {
                          final value = overrides[court.id] ?? court.isLive;
                          final isLoading = busyCourts.contains(court.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: SwitchListTile.adaptive(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(court.name),
                                subtitle: Text(
                                  value ? 'Visível para clientes' : 'Ocultada do app',
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                                ),
                                value: value,
                                onChanged: isLoading
                                    ? null
                                    : (newValue) async {
                                        sheetSetState(() => busyCourts.add(court.id));
                                        final success = await _updateCourtLiveStatus(court, newValue);
                                        if (!mounted) return;
                                        sheetSetState(() {
                                          busyCourts.remove(court.id);
                                          if (success) {
                                            overrides[court.id] = newValue;
                                            shouldRefresh = true;
                                          }
                                        });
                                      },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await _copyArenaLink(arena);
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Copiar link da arena'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compartilhe o link para que clientes encontrem os replays desta arena rapidamente.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (shouldRefresh) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _arenasFuture;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: future == null
            ? const _OwnerMessageList(
                child: _OwnerMessageView(
                  icon: Icons.info_outline,
                  title: 'Nenhum estabelecimento vinculado',
                  description: 'Faça login como proprietário para acessar o painel.',
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<ArenaModel>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                      return const _OwnerLoadingView();
                    }

                    if (snapshot.hasError) {
                      return _OwnerMessageList(
                        child: _OwnerMessageView(
                          icon: Icons.wifi_off,
                          title: 'Não foi possível carregar suas arenas',
                          description: 'Verifique sua conexão e tente novamente.',
                          onRetry: _refresh,
                        ),
                      );
                    }

                    final arenas = snapshot.data ?? const <ArenaModel>[];
                    if (arenas.isEmpty) {
                      return _OwnerMessageList(
                        child: _OwnerMessageView(
                          icon: Icons.stadium_outlined,
                          title: 'Nenhuma arena cadastrada',
                          description:
                              'Peça a um administrador para vincular um estabelecimento à sua conta.',
                          onRetry: _refresh,
                        ),
                      );
                    }

                    final selectedArena = _resolveSelectedArena(arenas);
                    final replays = selectedArena?.replays ?? const <ReplayModel>[];
                    final publicCount =
                        replays.where((replay) => replay.visibility == ReplayVisibility.public).length;
                    final expiredCount = replays.length - publicCount;
                    final isLive = selectedArena == null
                        ? false
                        : (_pendingLiveOverride[selectedArena.id] ?? selectedArena.isLive);

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (selectedArena != null)
                          _OwnerHeader(
                            arenas: arenas,
                            selectedArenaId: selectedArena.id,
                            onArenaChanged: (value) {
                              if (value == null || value == _selectedArenaId) return;
                              setState(() {
                                _selectedArenaId = value;
                                _pendingLiveOverride.remove(value);
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        if (selectedArena != null)
                          _OwnerStreamingCard(
                            arena: selectedArena,
                            isLive: isLive,
                            isLoading: _isUpdatingLive,
                            onToggle: (value) => _updateLiveStatus(selectedArena, value),
                          ),
                        if (selectedArena != null) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _openAdvancedControls(selectedArena),
                            icon: const Icon(Icons.tune),
                            label: const Text('Controles avançados'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Altere visibilidade das quadras, copie link público ou ative/desative a arena.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.mutedGray),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (selectedArena != null)
                          Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  icon: Icons.play_circle_outline,
                                  value: replays.length.toString(),
                                  label: 'Replays totais',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatsCard(
                                  icon: Icons.visibility_outlined,
                                  value: publicCount.toString(),
                                  label: 'Replays públicos',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatsCard(
                                  icon: Icons.history_toggle_off,
                                  value: expiredCount.toString(),
                                  label: 'Expirados',
                                ),
                              ),
                            ],
                          ),
                        if (selectedArena != null) ...[
                          const SizedBox(height: 16),
                          StatsCard(
                            icon: Icons.sports_volleyball_outlined,
                            value: selectedArena.courts.length.toString(),
                            label: selectedArena.courts.length == 1
                                ? 'Quadra disponível'
                                : 'Quadras disponíveis',
                          ),
                        ],
                        const SizedBox(height: 32),
                        Text(
                          'Replays recentes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (replays.isEmpty)
                          const _OwnerMessageCard(
                            icon: Icons.play_disabled_outlined,
                            title: 'Nenhum replay publicado',
                            description: 'Assim que suas câmeras registrarem jogadas, elas aparecerão aqui.',
                          )
                        else
                          Column(
                            children: replays.take(10).map((replay) {
                              return _ReplayListTile(
                                replay: replay,
                                onTap: () => context.push(
                                  ReplayPlayerScreen.routePath,
                                  extra: ReplayPlayerArguments(
                                    arenaName: selectedArena?.name ?? 'Arena',
                                    replay: replay,
                                  ),
                                ),
                                onShare: () => _handleShareReplay(replay),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  ArenaModel? _resolveSelectedArena(List<ArenaModel> arenas) {
    if (arenas.isEmpty) {
      return null;
    }

    if (_selectedArenaId != null) {
      for (final arena in arenas) {
        if (arena.id == _selectedArenaId) {
          return arena;
        }
      }
    }

    return arenas.first;
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader({
    required this.arenas,
    required this.selectedArenaId,
    required this.onArenaChanged,
  });

  final List<ArenaModel> arenas;
  final String selectedArenaId;
  final ValueChanged<String?> onArenaChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = arenas.firstWhere((arena) => arena.id == selectedArenaId);
    final locationLabel = selected.uf.isNotEmpty
        ? '${selected.city} · ${selected.uf.toUpperCase()}'
        : selected.city;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locationLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
        ),
        if (arenas.length > 1)
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: selectedArenaId,
              decoration: const InputDecoration(
                labelText: 'Selecionar arena',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: arenas
                  .map(
                    (arena) => DropdownMenuItem<String>(
                      value: arena.id,
                      child: Text(arena.name),
                    ),
                  )
                  .toList(),
              onChanged: onArenaChanged,
            ),
          ),
      ],
    );
  }
}

class _OwnerStreamingCard extends StatelessWidget {
  const _OwnerStreamingCard({
    required this.arena,
    required this.isLive,
    required this.isLoading,
    required this.onToggle,
  });

  final ArenaModel arena;
  final bool isLive;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'STREAM AO VIVO',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isLive,
                onChanged: isLoading ? null : onToggle,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white70;
                  }
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.white;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white24;
                  }
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white24;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isLive ? 'Transmitindo agora' : 'Offline',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${arena.replayCount} replays publicados',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: Colors.white70),
          ],
        ],
      ),
    );
  }
}

class _OwnerLoadingView extends StatelessWidget {
  const _OwnerLoadingView();

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

class _OwnerMessageList extends StatelessWidget {
  const _OwnerMessageList({required this.child});

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

class _OwnerMessageView extends StatelessWidget {
  const _OwnerMessageView({
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

class _OwnerMessageCard extends StatelessWidget {
  const _OwnerMessageCard({
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

class _ReplayListTile extends StatelessWidget {
  const _ReplayListTile({
    required this.replay,
    required this.onTap,
    this.onShare,
  });

  final ReplayModel replay;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.backgroundDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replay.title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${replay.courtName ?? 'Quadra'} · ${replay.timeAgoLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                  ),
                ],
              ),
            ),
            if (onShare != null) ...[
              IconButton(
                tooltip: 'Compartilhar replay',
                onPressed: onShare,
                icon: const Icon(Icons.ios_share, color: AppColors.primary),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: replay.visibility == ReplayVisibility.public
                    ? AppColors.primary
                    : AppColors.mutedGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                replay.visibility == ReplayVisibility.public ? 'PÚBLICO' : 'EXPIRADO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<ArenaModel>> _loadOwnerArenas(String ownerId) async {
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
        .eq('owner_id', ownerId)
        .order('created_at');

    return (response as List<dynamic>).map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final replays = (map['replays'] as List<dynamic>? ?? [])
          .map((replay) => normalizeReplayRow(Map<String, dynamic>.from(replay as Map<String, dynamic>)))
          .toList();
      map['replays'] = replays;
      return ArenaModel.fromJson(map);
    }).toList();
  } on PostgrestException catch (error) {
    throw Exception(error.message);
  }
}
