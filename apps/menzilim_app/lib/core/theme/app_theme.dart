import 'package:flutter/material.dart';

/// Uygulamanın açık/koyu temaları. Renkler tek bir seed'den türetilen
/// ColorScheme üzerinden gelir; ekranlar sabit renk yerine
/// `Theme.of(context).colorScheme` ve [AppStatusColors] kullanır.
/// İleride yapılacak premium tasarım bu dosyadan yönetilebilir.
class AppTheme {
  AppTheme._();

  /// Material 3'ün varsayılan seed'i: açık tema önceki görünümü korur.
  static const Color seedColor = Color(0xFF6750A4);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      extensions: [
        brightness == Brightness.dark
            ? AppStatusColors.dark
            : AppStatusColors.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outline),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// ColorScheme'de karşılığı olmayan anlamsal durum renkleri (başarı,
/// uyarı, bilgi). Koyu temada okunabilir tonlar kullanılır.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  const AppStatusColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  static const AppStatusColors light = AppStatusColors(
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFE8F5E9),
    warning: Color(0xFFE65100),
    warningContainer: Color(0xFFFFF3E0),
    info: Color(0xFF1565C0),
    infoContainer: Color(0xFFE3F2FD),
  );

  static const AppStatusColors dark = AppStatusColors(
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1E3A22),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF3E2A10),
    info: Color(0xFF64B5F6),
    infoContainer: Color(0xFF0F2D4A),
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;

    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Tema uzantısı yoksa (ör. basit test MaterialApp'i) parlaklığa göre
  /// varsayılan durum renkleri kullanılır.
  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppStatusColors.dark
          : AppStatusColors.light);
}
