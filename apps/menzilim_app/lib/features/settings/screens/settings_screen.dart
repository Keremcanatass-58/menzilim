import 'package:flutter/material.dart';

import '../../../core/auth/auth_scope.dart';
import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_theme.dart';

/// Dil ve tema tercihleri. Seçim anında uygulanır ve cihazda saklanır.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: ListView(
                padding: AppSpacing.screen(constraints.maxWidth),
                children: [
                  MenzilimSectionHeader(
                    title: l10n.settingsAppearance,
                    subtitle: l10n.settingsAppearanceSubtitle,
                  ),
                  MenzilimCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.language,
                          title: l10n.settingsLanguage,
                          child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: 'tr',
                                label: Text(l10n.settingsLanguageTurkish),
                              ),
                              ButtonSegment(
                                value: 'en',
                                label: Text(l10n.settingsLanguageEnglish),
                              ),
                            ],
                            selected: {settings.locale.languageCode},
                            onSelectionChanged: (selection) =>
                                settings.setLocale(Locale(selection.first)),
                          ),
                        ),
                        const Divider(),
                        _SettingsRow(
                          icon: Icons.palette_outlined,
                          title: l10n.settingsTheme,
                          subtitle: l10n.settingsThemeSystemHint,
                          child: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: const Icon(
                                  Icons.brightness_auto_outlined,
                                ),
                                label: Text(l10n.settingsThemeSystem),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: const Icon(Icons.light_mode_outlined),
                                label: Text(l10n.settingsThemeLight),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: const Icon(Icons.dark_mode_outlined),
                                label: Text(l10n.settingsThemeDark),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selection) =>
                                settings.setThemeMode(selection.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  MenzilimSectionHeader(title: l10n.settingsAccount),
                  MenzilimCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 20,
                              color: context.colors.error,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                l10n.settingsLogout,
                                style: context.textStyles.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.settingsLogoutHint,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Oturumu kapatır; yönlendirmeyi AuthGate yapar.
                        MenzilimButton(
                          label: l10n.settingsLogout,
                          icon: Icons.logout,
                          variant: MenzilimButtonVariant.secondary,
                          onPressed: () => AuthScope.of(context).logout(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      l10n.appTagline,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: context.textStyles.titleMedium),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Dar ekranda (400px) segmentler taşmasın diye tam genişlik.
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
