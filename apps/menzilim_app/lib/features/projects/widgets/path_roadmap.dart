import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_project.dart';

/// Yolun fazlarını tek şeritte gösterir: tamamlanan, içinde bulunulan ve
/// önündeki adımlar. Uzun listelerde yatay kaydırılır.
class PathRoadmap extends StatelessWidget {
  final UserProject project;

  const PathRoadmap({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.statusColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < project.steps.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colors.outlineVariant,
                ),
              ),
            _PhaseChip(
              label: _phaseLabel(project.steps[index]),
              completed: project.steps[index].isCompleted,
              current: project.steps[index].isAvailable,
              completedColor: status.success,
            ),
          ],
        ],
      ),
    );
  }

  /// Adım başlığının ilk iki kelimesi faz etiketi olarak yeterlidir.
  static String _phaseLabel(UserProjectStep step) {
    final words = step.title.split(' ');

    return words.length <= 2 ? step.title : words.take(2).join(' ');
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final bool completed;
  final bool current;
  final Color completedColor;

  const _PhaseChip({
    required this.label,
    required this.completed,
    required this.current,
    required this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final background = current
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;

    final foreground = current
        ? colors.onPrimaryContainer
        : (completed ? completedColor : colors.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed) ...[
            Icon(Icons.check, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: foreground,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
