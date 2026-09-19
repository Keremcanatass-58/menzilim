import 'package:flutter/widgets.dart';

import 'app_settings_controller.dart';

/// [AppSettingsController]'ı widget ağacına verir (Flutter'ın yerleşik
/// InheritedNotifier'ı; ek state-management paketi yok).
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope bulunamadı.');
    return scope!.notifier!;
  }
}
