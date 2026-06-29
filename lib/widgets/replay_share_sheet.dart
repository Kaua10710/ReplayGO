import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../models/replay_model.dart';

enum ReplayShareAction { copyLink, copySummary }

Future<String?> showReplayShareSheet(BuildContext context, ReplayModel replay) async {
  final shareUrl = 'https://replaygo.app/replays/${replay.id}';

  final action = await showModalBottomSheet<ReplayShareAction>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compartilhar replay',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              replay.title,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
            ),
            const SizedBox(height: 16),
            _ShareActionTile(
              icon: Icons.link,
              label: 'Copiar link',
              description: 'Copia a URL do replay para enviar onde quiser.',
              onTap: () => Navigator.of(context).pop(ReplayShareAction.copyLink),
            ),
            _ShareActionTile(
              icon: Icons.message_outlined,
              label: 'Copiar mensagem pronta',
              description: 'Resumo com título e link para colar em redes sociais.',
              onTap: () => Navigator.of(context).pop(ReplayShareAction.copySummary),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );

  if (action == null) return null;

  switch (action) {
    case ReplayShareAction.copyLink:
      await Clipboard.setData(ClipboardData(text: shareUrl));
      return 'Link do replay copiado.';
    case ReplayShareAction.copySummary:
      final summary = 'Acabei de assistir ao replay "${replay.title}" na ReplayGO. Veja também: $shareUrl';
      await Clipboard.setData(ClipboardData(text: summary));
      return 'Resumo copiado para a área de transferência.';
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedGray),
          ],
        ),
      ),
    );
  }
}
