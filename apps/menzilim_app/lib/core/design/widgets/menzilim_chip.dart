import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../design_tokens.dart';

enum MenzilimChipTone { neutral, primary, secondary, success, warning }

/// Küçük etiket: kaynak adı, seviye, kategori, durum rozeti.
class MenzilimChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final MenzilimChipTone tone;

  const MenzilimChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = MenzilimChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.statusColors;

    final (Color background, Color foreground) = switch (tone) {
      MenzilimChipTone.neutral => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
        ),
      MenzilimChipTone.primary => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
      MenzilimChipTone.secondary => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
        ),
      MenzilimChipTone.success => (status.successContainer, status.success),
      MenzilimChipTone.warning => (status.warningContainer, status.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
