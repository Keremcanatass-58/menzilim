import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/news_item.dart';
import '../services/news_link_opener.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';

/// Kullanıcının alanındaki tüm haberler (en fazla 10, backend sıralı).
class NewsScreen extends StatefulWidget {
  // Testlerde sahte servis/bağlantı açıcı verilebilir.
  final NewsService? newsService;
  final NewsLinkOpener? openLink;

  const NewsScreen({
    super.key,
    this.newsService,
    this.openLink,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsService _newsService =
      widget.newsService ?? NewsService(ApiClient());

  late final NewsLinkOpener _openLink =
      widget.openLink ?? openNewsLinkExternally;

  final TokenStorage _tokenStorage = TokenStorage();

  List<NewsItem> _news = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final news = await _newsService.getMyNews(token);

      if (!mounted) return;

      setState(() {
        _news = news;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.newsLoadError;
      });
    }
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MenzilimErrorView(
        message: _errorMessage!,
        onRetry: _loadNews,
      );
    }

    if (_news.isEmpty) {
      return MenzilimEmptyView(
        icon: Icons.feed_outlined,
        message: context.l10n.newsEmpty,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxReadingWidth,
          ),
          child: RefreshIndicator(
            onRefresh: _loadNews,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screen(constraints.maxWidth),
              itemCount: _news.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return MenzilimSectionHeader(
                    title: context.l10n.newsSectionTitle,
                    subtitle: context.l10n.newsSectionSubtitle,
                  );
                }

                final item = _news[index - 1];

                return MenzilimEntrance(
                  order: index,
                  child: NewsCard(
                    item: item,
                    onOpen: () => openNewsItem(context, item, _openLink),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newsScreenTitle)),
      body: SafeArea(child: _buildBody(context)),
    );
  }
}
