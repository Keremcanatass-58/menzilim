import 'package:flutter/material.dart';

import '../design_tokens.dart';

enum MenzilimButtonVariant { primary, secondary, text }

/// Uygulamadaki ana eylem butonu: yükseklik, yuvarlaklık ve yükleniyor
/// durumu tek yerden gelir.
class MenzilimButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MenzilimButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;

  const MenzilimButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = MenzilimButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final onTap = isLoading ? null : onPressed;

    final button = switch (variant) {
      MenzilimButtonVariant.primary => icon == null || isLoading
          ? FilledButton(onPressed: onTap, child: child)
          : FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: child,
            ),
      MenzilimButtonVariant.secondary => icon == null || isLoading
          ? OutlinedButton(onPressed: onTap, child: child)
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: child,
            ),
      MenzilimButtonVariant.text => icon == null || isLoading
          ? TextButton(onPressed: onTap, child: child)
          : TextButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: child,
            ),
    };

    if (!fullWidth) return button;

    return SizedBox(
      width: double.infinity,
      height: variant == MenzilimButtonVariant.text ? null : 54,
      child: button,
    );
  }
}

/// Bölüm/ekran girişlerinde ölçülü bir belirme animasyonu.
class MenzilimEntrance extends StatelessWidget {
  final Widget child;
  final int order;

  const MenzilimEntrance({
    super.key,
    required this.child,
    this.order = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Sıraya göre küçük gecikme; toplam süre kısa tutulur.
    final delay = Duration(milliseconds: 40 * order.clamp(0, 6));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium + delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
