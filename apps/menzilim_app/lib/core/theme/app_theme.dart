import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// MENZİLİM'in renk, tipografi ve bileşen dili.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF176B5B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = brightness == Brightness.light
        ? ColorScheme.fromSeed(seedColor: seedColor).copyWith(
            primary: const Color(0xFF176B5B),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFD8EEE8),
            onPrimaryContainer: const Color(0xFF103B34),
            secondary: const Color(0xFF9A512F),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFF5E3D9),
            onSecondaryContainer: const Color(0xFF4A281A),
            tertiary: const Color(0xFF3F5F9A),
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFE1E9F7),
            onTertiaryContainer: const Color(0xFF1D3155),
            surface: const Color(0xFFF5F7F6),
            onSurface: const Color(0xFF182321),
            surfaceContainerLowest: const Color(0xFFFFFFFF),
            surfaceContainerLow: const Color(0xFFFFFFFF),
            surfaceContainer: const Color(0xFFEEF2F0),
            surfaceContainerHigh: const Color(0xFFE7ECE9),
            surfaceContainerHighest: const Color(0xFFDDE5E1),
            onSurfaceVariant: const Color(0xFF52615D),
            outline: const Color(0xFF7D8B86),
            outlineVariant: const Color(0xFFD5DEDA),
            surfaceTint: const Color(0xFF176B5B),
          )
        : ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          ).copyWith(
            primary: const Color(0xFF80CBB8),
            onPrimary: const Color(0xFF073B32),
            primaryContainer: const Color(0xFF19483F),
            onPrimaryContainer: const Color(0xFFD8EEE8),
            secondary: const Color(0xFFE5A27F),
            onSecondary: const Color(0xFF4A281A),
            secondaryContainer: const Color(0xFF573629),
            onSecondaryContainer: const Color(0xFFF5E3D9),
            tertiary: const Color(0xFFA8BCE8),
            onTertiary: const Color(0xFF1D3155),
            tertiaryContainer: const Color(0xFF2D4168),
            onTertiaryContainer: const Color(0xFFE1E9F7),
            surface: const Color(0xFF111A18),
            onSurface: const Color(0xFFE7EFEC),
            surfaceContainerLowest: const Color(0xFF0C1312),
            surfaceContainerLow: const Color(0xFF18221F),
            surfaceContainer: const Color(0xFF1D2925),
            surfaceContainerHigh: const Color(0xFF26332F),
            surfaceContainerHighest: const Color(0xFF303E39),
            onSurfaceVariant: const Color(0xFFB5C2BD),
            outline: const Color(0xFF879791),
            outlineVariant: const Color(0xFF3C4A44),
            surfaceTint: const Color(0xFF80CBB8),
          );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      brightness: brightness,
    );

    final text = _typography(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      textTheme: text,
      extensions: [
        brightness == Brightness.dark
            ? AppStatusColors.dark
            : AppStatusColors.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        space: AppSpacing.xl,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        linearMinHeight: 8,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: text.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          textStyle: text.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(color: colors.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(color: colors.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        labelStyle: text.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.fieldRadius,
          side: BorderSide(color: colors.outlineVariant),
        ),
        titleTextStyle: text.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Başlıklarda daha sıkı harf aralığı ve güçlü ağırlık; gövde metinlerinde
  /// okunaklı satır yüksekliği.
  static TextTheme _typography(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
    success: Color(0xFF176B5B),
    successContainer: Color(0xFFD8EEE8),
    warning: Color(0xFF9A512F),
    warningContainer: Color(0xFFF5E3D9),
    info: Color(0xFF3F5F9A),
    infoContainer: Color(0xFFE1E9F7),
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
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
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
