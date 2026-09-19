import 'package:flutter/material.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadNews,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_news.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.newsEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _news.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _news[index];

            return NewsCard(
              item: item,
              onOpen: () => openNewsItem(context, item, _openLink),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.newsScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }
}
