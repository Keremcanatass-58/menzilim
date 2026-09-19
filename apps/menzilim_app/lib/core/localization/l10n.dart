import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../settings/app_settings_controller.dart';

export '../../l10n/generated/app_localizations.dart';

extension AppLocalizationsLabels on AppLocalizations {
  /// Backend'in deneyim seviyesi değeri (Beginner/Intermediate/Advanced)
  /// için görünen etiket. Bilinmeyen değer olduğu gibi gösterilir.
  String experienceLevelLabel(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':
        return experienceBeginner;
      case 'intermediate':
        return experienceIntermediate;
      case 'advanced':
        return experienceAdvanced;
      default:
        return value;
    }
  }
}

extension AppLocalizationsContext on BuildContext {
  /// Geçerli dilin metinleri. Localization delegate'leri olmayan bir ağaçta
  /// (ör. tek bir widget'ı test eden basit MaterialApp) varsayılan dil
  /// (Türkçe) kullanılır.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(AppSettingsController.defaultLocale);
}
