import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../models/news_item.dart';
import '../services/news_link_opener.dart';

/// Ör. "11 Kasım 2025" / "November 11, 2025". Yalnızca tarih gösterilir
/// (saat dilimi farkı önemsiz). intl tarih verisine ihtiyaç duymaz.
String formatNewsDate(AppLocalizations l10n, DateTime date) {
  return l10n.newsDate(
    date.day,
    l10n.monthName('m${date.month}'),
    date.year.toString(),
  );
}

/// Haberin kaynağını açar; açılamazsa kullanıcıya bildirir.
Future<void> openNewsItem(
  BuildContext context,
  NewsItem item,
  NewsLinkOpener openLink,
) async {
  final uri = Uri.tryParse(item.sourceUrl);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;

  if (uri == null || !uri.hasScheme) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.newsInvalidLink)),
    );
    return;
  }

  final opened = await openLink(uri);

  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.newsOpenError)),
    );
  }
}

/// Haber kartı: kaynak rozeti, tarih, başlık, özet, (varsa) görsel ve
/// kaynağa giden "Haberi İncele" bağlantısı. Renkler temadan gelir.
class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onOpen;

  /// Dashboard'daki kısa görünümde özet daha az satır gösterir.
  final bool compact;

  const NewsCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final host = item.sourceHost;

    return MenzilimCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                // Görsel yüklenemezse kart görselsiz devam eder.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: MenzilimChip(
                        label: item.sourceName,
                        tone: MenzilimChipTone.secondary,
                      ),
                    ),
                    if (item.publishedAt != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          formatNewsDate(context.l10n, item.publishedAt!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.summary,
                  maxLines: compact ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(context.l10n.newsReadMore),
                ),
                if (host != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  // Kaynak adresi açıkça gösterilir.
                  Expanded(
                    child: Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
