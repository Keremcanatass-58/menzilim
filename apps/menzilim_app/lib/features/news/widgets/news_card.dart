import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final host = item.sourceHost;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (item.publishedAt != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        formatNewsDate(context.l10n, item.publishedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.summary,
                  maxLines: compact ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(context.l10n.newsReadMore),
                ),
                if (host != null) ...[
                  const SizedBox(width: 4),
                  // Kaynak adresi açıkça gösterilir.
                  Expanded(
                    child: Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
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
