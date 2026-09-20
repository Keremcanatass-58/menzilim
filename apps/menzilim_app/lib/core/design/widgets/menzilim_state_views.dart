import 'package:flutter/material.dart';

import '../../localization/l10n.dart';
import '../../theme/app_theme.dart';
import '../design_tokens.dart';
import 'menzilim_button.dart';
import 'menzilim_card.dart';

/// Ekran ortasında hata durumu: ikon, mesaj ve tekrar dene.
class MenzilimErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const MenzilimErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 28,
                  color: context.colors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                MenzilimButton(
                  label: context.l10n.commonRetry,
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  variant: MenzilimButtonVariant.secondary,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ekran ortasında boş durum.
class MenzilimEmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const MenzilimEmptyView({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm içinde (dashboard kartları gibi) kısa hata satırı.
/// Testlerin beklediği Wrap yapısı korunur.
class MenzilimInlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MenzilimInlineError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MenzilimCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          Text(message),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

/// Bölüm içinde boş durum satırı.
class MenzilimInlineEmpty extends StatelessWidget {
  final String message;

  const MenzilimInlineEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MenzilimCard(
      child: Text(
        message,
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
