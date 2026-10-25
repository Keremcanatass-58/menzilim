import 'package:flutter/widgets.dart';

/// Tekrarlanan ölçüler tek yerde. Premium tasarımın ritmi 4'ün katlarıdır.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Bölümler arası boşluk.
  static const double section = 32;

  /// Ekran kenar boşlukları (dar ekranda daha küçük).
  static const EdgeInsets screenCompact = EdgeInsets.fromLTRB(20, 20, 20, 40);
  static const EdgeInsets screenWide = EdgeInsets.fromLTRB(32, 32, 32, 56);

  static EdgeInsets screen(double width) =>
      width < AppBreakpoints.tablet ? screenCompact : screenWide;
}

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 8;
  static const double xl = 12;
  static const double pill = 999;

  static final BorderRadius cardRadius = BorderRadius.circular(lg);
  static final BorderRadius fieldRadius = BorderRadius.circular(10);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 768;
  static const double desktop = 1180;

  /// İçeriğin okunabilir kaldığı en geniş ölçü.
  static const double maxContentWidth = 1080;
  static const double maxReadingWidth = 760;
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
}
