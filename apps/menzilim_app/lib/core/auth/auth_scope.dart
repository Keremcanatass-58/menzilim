import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// [AuthController]'ı widget ağacına verir (Flutter'ın yerleşik
/// InheritedNotifier'ı; ek state-management paketi yok).
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope bulunamadı.');
    return scope!.notifier!;
  }
}
