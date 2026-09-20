import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../localization/l10n.dart';
import '../../theme/app_theme.dart';
import '../design_tokens.dart';

/// Marka varlıkları tek dosyadan yönetilir: sembol (mark) ve yazı (wordmark)
/// ayrı ayrı ya da birlikte (lockup) kullanılabilir.
class MenzilimBrand {
  MenzilimBrand._();

  static const String markAsset = 'assets/brand/menzilim_mark.svg';
}

/// MENZİLİM sembolü. Varsayılan olarak temanın birincil rengiyle çizilir.
class MenzilimLogoMark extends StatelessWidget {
  final double size;
  final Color? color;

  /// true ise sembol, marka renginde yuvarlatılmış bir kare içinde gösterilir.
  final bool boxed;

  const MenzilimLogoMark({
    super.key,
    this.size = 32,
    this.color,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final markColor =
        color ?? (boxed ? context.colors.onPrimary : context.colors.primary);

    final mark = SvgPicture.asset(
      MenzilimBrand.markAsset,
      width: boxed ? size * 0.68 : size,
      height: boxed ? size * 0.68 : size,
      colorFilter: ColorFilter.mode(markColor, BlendMode.srcIn),
    );

    if (!boxed) return mark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }
}

/// MENZİLİM yazısı. Marka adı çevrilmez; yalnızca biçimlendirilir.
class MenzilimWordmark extends StatelessWidget {
  final TextStyle? style;
  final Color? color;

  const MenzilimWordmark({super.key, this.style, this.color});

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.textStyles.titleMedium;

    return Text(
      context.l10n.appName,
      style: base?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Sembol + yazı (isteğe bağlı slogan) kilidi.
class MenzilimLogo extends StatelessWidget {
  final double markSize;
  final TextStyle? wordmarkStyle;
  final bool showTagline;
  final bool boxedMark;

  const MenzilimLogo({
    super.key,
    this.markSize = 32,
    this.wordmarkStyle,
    this.showTagline = false,
    this.boxedMark = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenzilimLogoMark(size: markSize, boxed: boxedMark),
        SizedBox(width: markSize * 0.4),
        Flexible(child: MenzilimWordmark(style: wordmarkStyle)),
      ],
    );

    if (!showTagline) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.appTagline,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
