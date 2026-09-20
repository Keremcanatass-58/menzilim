import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
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
      appBar: AppBar(title: Text(context.l10n.discoverTitle)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MenzilimErrorView(
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });

          _loadContent();
        },
      );
    }

    if (_contents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadContent,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            MenzilimEmptyView(
              icon: Icons.local_library_outlined,
              message: context.l10n.discoverEmpty,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.tablet;

        return RefreshIndicator(
          onRefresh: _loadContent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screen(constraints.maxWidth),
                children: [
                  MenzilimSectionHeader(
                    title: context.l10n.discoverHeadline,
                    subtitle: context.l10n.discoverSubtitle,
                  ),
                  if (isWide)
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final content in _contents)
                          SizedBox(
                            width: (constraints.maxWidth.clamp(
                                          0,
                                          AppBreakpoints.maxContentWidth,
                                        ) -
                                        AppSpacing.screenWide.horizontal -
                                        AppSpacing.md) /
                                    2 -
                                0.01,
                            child: _ContentCard(
                              content: content,
                              onTap: () => _openDetail(content),
                            ),
                          ),
                      ],
                    )
                  else
                    ..._contents.map(
                      (content) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ContentCard(
                          content: content,
                          onTap: () => _openDetail(content),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Öğrenme kitaplığındaki içerik kartı.
class _ContentCard extends StatelessWidget {
  final ContentResponse content;
  final VoidCallback onTap;

  const _ContentCard({
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MenzilimCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: MenzilimChip(
                  label: context.l10n.experienceLevelLabel(content.level),
                  tone: MenzilimChipTone.primary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            content.title,
            style: context.textStyles.titleLarge,
          ),
          if (content.description != null &&
              content.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              content.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.public, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  content.source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(
                Icons.schedule_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.commonMinutesShort(content.readingTimeMinutes),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contentDetailTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReadingWidth,
              ),
              child: SingleChildScrollView(
                padding: AppSpacing.screen(constraints.maxWidth),
                child: MenzilimEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero: durum/seviye rozeti ve başlık
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          MenzilimChip(
                            label: _isCompleted
                                ? l10n.contentCompletedBadge
                                : l10n.experienceLevelLabel(content.level),
                            icon: _isCompleted ? Icons.check_circle : null,
                            tone: _isCompleted
                                ? MenzilimChipTone.success
                                : MenzilimChipTone.primary,
                          ),
                          MenzilimChip(
                            label: content.source,
                            icon: Icons.public,
                          ),
                          MenzilimChip(
                            label: l10n.commonMinutes(
                              content.readingTimeMinutes,
                            ),
                            icon: Icons.schedule_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        content.title,
                        style: context.textStyles.headlineMedium,
                      ),

                      if (content.description != null &&
                          content.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.contentAbout,
                          style: context.textStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          content.description!,
                          style: context.textStyles.bodyLarge?.copyWith(
                            height: 1.6,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // Birincil eylem
                      MenzilimButton(
                        label: l10n.contentOpen,
                        onPressed: _isLoadingProgress
                            ? null
                            : () => _openUrl(context),
                        icon: Icons.open_in_new,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MenzilimButton(
                        label: _isCompleted
                            ? l10n.contentCompletedButton
                            : l10n.contentMarkComplete,
                        isLoading: _isCompleting,
                        onPressed:
                            _isLoadingProgress || _isCompleting || _isCompleted
                                ? null
                                : _completeContent,
                        icon: _isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        variant: MenzilimButtonVariant.secondary,
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _errorMessage!,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
