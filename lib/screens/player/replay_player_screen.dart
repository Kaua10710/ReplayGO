import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/replay_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/replay_share_sheet.dart';

class ReplayPlayerArguments {
  const ReplayPlayerArguments({
    required this.arenaName,
    required this.replay,
  });

  final String arenaName;
  final ReplayModel replay;
}

class ReplayPlayerScreen extends StatefulWidget {
  const ReplayPlayerScreen({super.key, this.routeData});

  static const String routeName = 'replay-player';
  static const String routePath = '/replay';

  final Object? routeData;

  @override
  State<ReplayPlayerScreen> createState() => _ReplayPlayerScreenState();
}

class _ReplayPlayerScreenState extends State<ReplayPlayerScreen> {
  bool _savingToProfile = false;

  ReplayPlayerArguments get _args => widget.routeData is ReplayPlayerArguments
      ? widget.routeData as ReplayPlayerArguments
      : ReplayPlayerArguments(
          arenaName: 'Arena Beira Mar · Quadra 1',
          replay: ReplayModel(
            id: 'replay-1',
            arenaId: 'arena-1',
            courtId: 'court-1',
            ownerId: 'profile-owner',
            title: 'Ponto decisivo',
            description: 'Match point que garantiu a vitória.',
            durationSeconds: 42,
            recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
            visibility: ReplayVisibility.public,
            createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
            updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
            courtName: 'Quadra 1',
            arenaName: 'Arena Beira Mar',
          ),
        );

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

  Future<void> _handleShare() async {
    final message = await showReplayShareSheet(context, _args.replay);
    if (message != null) _showSnack(message);
  }

  Future<void> _handleSaveToProfile() async {
    if (_savingToProfile) return;

    final userId = context.read<UserProvider>().id;
    if (userId.isEmpty) {
      _showSnack('Entre para salvar replays no seu perfil.', isError: true);
      return;
    }

    setState(() => _savingToProfile = true);
    try {
      await Supabase.instance.client.from('saved_replays').upsert({
        'replay_id': _args.replay.id,
        'user_id': userId,
      });
      _showSnack('Replay salvo no seu perfil.');
    } on PostgrestException catch (error) {
      _showSnack(error.message, isError: true);
    } catch (_) {
      _showSnack('Não foi possível salvar o replay.', isError: true);
    } finally {
      if (mounted) setState(() => _savingToProfile = false);
    }
  }

  void _handleSaveToGallery() {
    // O download para a galeria depende do arquivo de vídeo real, que entra
    // junto com a integração do player (better_player/video_player).
    _showSnack('O download para a galeria chega com o player de vídeo real.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = _args;

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
                          '${args.replay.title} · ${args.replay.durationLabel}',
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
                    onPressed: _handleShare,
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
                          onPressed: _handleSaveToGallery,
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
                          onPressed: _savingToProfile ? null : _handleSaveToProfile,
                          icon: _savingToProfile
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.bookmark_outline),
                          label: Text(_savingToProfile ? 'Salvando...' : 'Salvar no perfil'),
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
