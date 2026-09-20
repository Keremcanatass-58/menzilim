import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../design_tokens.dart';

/// Yuvarlatılmış, değeri yumuşak geçişle animasyonlanan ilerleme çubuğu.
class MenzilimProgressBar extends StatelessWidget {
  /// 0..1 aralığı.
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  const MenzilimProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => LinearProgressIndicator(
        value: animated,
        minHeight: height,
        borderRadius: BorderRadius.circular(height),
        color: color ?? context.colors.primary,
        backgroundColor: trackColor ?? context.colors.surfaceContainerHighest,
      ),
    );
  }
}
