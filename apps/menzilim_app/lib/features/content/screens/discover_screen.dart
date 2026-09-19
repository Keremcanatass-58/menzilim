import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/content_response.dart';
import '../services/content_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ContentService _contentService =
      ContentService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  List<ContentResponse> _contents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final contents =
          await _contentService.getMyContent(token);

      if (!mounted) return;

      setState(() {
        _contents = contents;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.discoverLoadError;
      });
    }
  }

  void _openDetail(ContentResponse content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(
          content: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.discoverTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadContent();
                },
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_contents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadContent,
        child: ListView(
          children: [
            const SizedBox(height: 180),
            Center(
              child: Text(
                context.l10n.discoverEmpty,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.l10n.discoverHeadline,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.discoverSubtitle,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ..._contents.map(
            (content) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ContentCard(
                content: content,
                onTap: () => _openDetail(content),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentResponse content;
  final VoidCallback onTap;

  const _ContentCard({
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.experienceLevelLabel(content.level),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (content.description != null &&
                content.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    content.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.commonMinutesShort(content.readingTimeMinutes),
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContentDetailScreen extends StatefulWidget {
  final ContentResponse content;

  const ContentDetailScreen({
    super.key,
    required this.content,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final ContentService _contentService = ContentService(ApiClient());
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoadingProgress = true;
  bool _isCompleting = false;
  bool _isCompleted = false;
  String? _errorMessage;

  ContentResponse get content => widget.content;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<String?> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Oturum bilgisi bulunamadı.');
    }

    return token;
  }

  Future<void> _loadProgress() async {
    try {
      final token = await _getToken();

      final progress = await _contentService.getProgress(
        token!,
        content.id,
      );

      if (!mounted) return;

      setState(() {
        _isCompleted = progress['isCompleted'] == true;
        _isLoadingProgress = false;
        _errorMessage = null;
      });

      if (progress['isStarted'] != true && !_isCompleted) {
        await _startContent(token);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProgress = false;
        _errorMessage = context.l10n.contentProgressLoadError;
      });
    }
  }

  Future<void> _startContent(String token) async {
    try {
      await _contentService.startContent(
        token,
        content.id,
      );
    } catch (_) {
      // İlerleme kaydı başarısız olsa bile kullanıcı içeriği açabilsin.
    }
  }

  Future<void> _completeContent() async {
    if (_isCompleting || _isCompleted) return;

    try {
      setState(() {
        _isCompleting = true;
      });

      final token = await _getToken();

      final progress = await _contentService.completeContent(
        token!,
        content.id,
      );

      if (!mounted) return;

      setState(() {
        _isCompleted = progress['isCompleted'] == true;
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.contentCompletedToast),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.contentCompleteError),
        ),
      );
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(content.url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.contentInvalidLink),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.contentOpenError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.contentDetailTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isCompleted
                    ? context.l10n.contentCompletedBadge
                    : context.l10n.experienceLevelLabel(content.level),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    content.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.commonMinutes(content.readingTimeMinutes),
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (content.description != null &&
                content.description!.isNotEmpty) ...[
              Text(
                context.l10n.contentAbout,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content.description!,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoadingProgress
                    ? null
                    : () => _openUrl(context),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  context.l10n.contentOpen,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoadingProgress ||
                        _isCompleting ||
                        _isCompleted
                    ? null
                    : _completeContent,
                icon: _isCompleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                label: Text(
                  _isCompleted
                      ? context.l10n.contentCompletedButton
                      : context.l10n.contentMarkComplete,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: context.colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
