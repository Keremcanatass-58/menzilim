import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../design_tokens.dart';

/// Kart yüzeyi tonu.
enum MenzilimCardTone {
  /// Varsayılan: hafif yüzey + ince çerçeve.
  surface,

  /// Vurgulu kart (ör. günün hedefi).
  primary,

  /// Yalnızca çerçeve; arka plan saydam.
  outlined,
}

/// Uygulamadaki tüm kartların ortak gövdesi: yuvarlaklık, çerçeve, dolgu ve
/// dokunma geri bildirimi tek yerden gelir.
class MenzilimCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final MenzilimCardTone tone;
  final bool selected;

  const MenzilimCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.tone = MenzilimCardTone.surface,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final background = switch (tone) {
      MenzilimCardTone.surface => colors.surfaceContainerLow,
      MenzilimCardTone.primary => colors.primaryContainer,
      MenzilimCardTone.outlined => Colors.transparent,
    };

    final border = switch (tone) {
      MenzilimCardTone.primary => Colors.transparent,
      _ => selected ? colors.primary : colors.outlineVariant,
    };

    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}
