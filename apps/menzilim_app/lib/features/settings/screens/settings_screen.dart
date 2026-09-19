import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SettingsSection(
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
                const SizedBox(height: 16),
                _SettingsSection(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsTheme,
                  subtitle: l10n.settingsThemeSystemHint,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
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
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border.all(color: context.colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Dar ekranda (400px) segmentler taşmasın diye tam genişlik.
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
