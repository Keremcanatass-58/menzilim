import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/token_storage.dart';
import '../../daily_plan/models/daily_plan_response.dart';
import '../../daily_plan/services/daily_plan_service.dart';
import '../models/dashboard_response.dart';
import '../services/dashboard_service.dart';
import '../../content/models/content_recommendation_response.dart';
import '../../content/models/content_response.dart';
import '../../content/services/content_service.dart';
import '../../content/screens/discover_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../ai_coach/screens/ai_coach_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../news/models/news_item.dart';
import '../../news/screens/news_screen.dart';
import '../../news/services/news_link_opener.dart';
import '../../news/services/news_service.dart';
import '../../news/widgets/news_card.dart';
import '../../skills/models/skill_progress_response.dart';
import '../../skills/screens/skills_screen.dart';
import '../../skills/services/skill_service.dart';
import '../widgets/dashboard_skills_summary.dart';

class DashboardScreen extends StatefulWidget {
  // Testlerde sahte servisler verilebilir; normalde gerçek API kullanılır.
  final DashboardService? dashboardService;
  final DailyPlanService? dailyPlanService;
  final ContentService? contentService;
  final SkillService? skillService;
  final NewsService? newsService;
  final NewsLinkOpener? openNewsLink;

  const DashboardScreen({
    super.key,
    this.dashboardService,
    this.dailyPlanService,
    this.contentService,
    this.skillService,
    this.newsService,
    this.openNewsLink,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService(ApiClient());

  late final DailyPlanService _dailyPlanService =
      widget.dailyPlanService ?? DailyPlanService(ApiClient());

  late final ContentService _contentService =
      widget.contentService ?? ContentService(ApiClient());

  late final SkillService _skillService =
      widget.skillService ?? SkillService(ApiClient());

  late final NewsService _newsService =
      widget.newsService ?? NewsService(ApiClient());

  late final NewsLinkOpener _openNewsLink =
      widget.openNewsLink ?? openNewsLinkExternally;

  final TokenStorage _tokenStorage = TokenStorage();

  DashboardResponse? _dashboard;
  DailyPlanResponse? _dailyPlan;

  bool _isLoading = true;
  String? _errorMessage;
  String? _completingTaskId;

  // Öneriler dashboard'dan bağımsız yüklenir; hataları dashboard'u düşürmez.
  List<ContentRecommendationResponse> _recommendations = [];
  bool _isLoadingRecommendations = true;
  String? _recommendationsError;
  int _recommendationsRequestId = 0;

  String? _openingContentId;

  // Beceri özeti de bağımsız yüklenir; hatası dashboard'u düşürmez.
  List<SkillProgressResponse> _skills = [];
  bool _isLoadingSkills = true;
  String? _skillsError;
  int _skillsRequestId = 0;

  // Haberler de bağımsız yüklenir; hatası dashboard'u düşürmez.
  static const int _dashboardNewsCount = 3;
  List<NewsItem> _news = [];
  bool _isLoadingNews = true;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRecommendations();
    _loadSkills();
    _loadNews();
  }

  Future<void> _loadNews() async {
    // İlk yüklemede state zaten "yükleniyor"; initState içinde setState gerekmez.
    if (mounted && !_isLoadingNews) {
      setState(() {
        _isLoadingNews = true;
        _newsError = null;
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
        _isLoadingNews = false;
        _newsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingNews = false;
        _newsError = context.l10n.newsLoadError;
      });
    }
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openNewsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewsScreen(newsService: _newsService, openLink: _openNewsLink),
      ),
    );
  }

  Widget _buildNewsSection() {
    Widget body;

    if (_isLoadingNews) {
      body = const _SectionLoader();
    } else if (_newsError != null) {
      body = MenzilimInlineError(message: _newsError!, onRetry: _loadNews);
    } else if (_news.isEmpty) {
      body = MenzilimInlineEmpty(message: context.l10n.newsEmpty);
    } else {
      body = Column(
        children: _news
            .take(_dashboardNewsCount)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: NewsCard(
                  item: item,
                  compact: true,
                  onOpen: () => openNewsItem(context, item, _openNewsLink),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(
          title: context.l10n.newsSectionTitle,
          subtitle: context.l10n.newsSectionSubtitle,
          actionLabel: _news.isEmpty ? null : context.l10n.newsViewAll,
          onAction: _news.isEmpty ? null : _openNewsScreen,
        ),
        body,
      ],
    );
  }

  Future<void> _loadSkills() async {
    final requestId = ++_skillsRequestId;

    // İlk yüklemede state zaten "yükleniyor"; initState içinde setState gerekmez.
    if (mounted && !_isLoadingSkills) {
      setState(() {
        _isLoadingSkills = true;
        _skillsError = null;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final skills = await _skillService.getMySkills(token);

      if (!mounted || requestId != _skillsRequestId) return;

      setState(() {
        _skills = skills;
        _isLoadingSkills = false;
        _skillsError = null;
      });
    } catch (e) {
      if (!mounted || requestId != _skillsRequestId) return;

      setState(() {
        _isLoadingSkills = false;
        _skillsError = context.l10n.dashboardSkillsLoadError;
      });
    }
  }

  void _openSkills() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SkillsScreen()));
  }

  Future<void> _loadRecommendations() async {
    // Üst üste yenilemelerde yalnızca en son isteğin sonucu uygulanır.
    final requestId = ++_recommendationsRequestId;

    // İlk yüklemede state zaten "yükleniyor"; initState içinde setState gerekmez.
    if (mounted && !_isLoadingRecommendations) {
      setState(() {
        _isLoadingRecommendations = true;
        _recommendationsError = null;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final recommendations = await _contentService.getRecommendations(token);

      if (!mounted || requestId != _recommendationsRequestId) return;

      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
        _recommendationsError = null;
      });
    } catch (e) {
      if (!mounted || requestId != _recommendationsRequestId) return;

      setState(() {
        _isLoadingRecommendations = false;
        _recommendationsError = context.l10n.dashboardRecommendationsLoadError;
      });
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      // Günlük plan önce istenir: günün ilk açılışında planı bu çağrı
      // oluşturur. Paralel istekte özet kartı planı henüz görmediği için
      // kısa süre "0 / 0 görev" gösteriyordu.
      final dailyPlan = await _dailyPlanService.getToday(token);
      final dashboard = await _dashboardService.getDashboard(token);

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _dailyPlan = dailyPlan;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = context.l10n.dashboardLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(DailyTaskResponse task) async {
    if (task.isCompleted) {
      return;
    }

    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _completingTaskId = task.id;
    });

    try {
      final updatedPlan = await _dailyPlanService.completeTask(token, task.id);

      if (!mounted) return;

      setState(() {
        _dailyPlan = updatedPlan;
        _completingTaskId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.commonTaskCompleted(task.title)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _completingTaskId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dashboardTaskCompleteError)),
      );
    }
  }

  // İçeriğe bağlanabilen görev tipleri (Quiz/Review içerik açmaz).
  static const Set<String> _contentTaskTypes = {'learn', 'practice'};

  bool _taskOpensContent(DailyTaskResponse task) {
    return _contentTaskTypes.contains(task.taskType.toLowerCase()) &&
        task.contentId != null &&
        task.contentId!.isNotEmpty;
  }

  void _onTaskTap(DailyTaskResponse task) {
    if (_taskOpensContent(task)) {
      _openContentById(task.contentId!, task: task);
    } else if (task.taskType.toLowerCase() == 'quiz') {
      _openQuiz(task);
    } else {
      _completeTask(task);
    }
  }

  // Günlük plan görevleri ve öneri kartları için ortak içerik açma akışı.
  // Görevden açıldıysa ([task] verilirse) dönüşte içerik tamamlanmışsa
  // görev de tamamlanır.
  Future<void> _openContentById(
    String contentId, {
    DailyTaskResponse? task,
  }) async {
    // Aynı anda birden fazla detay sayfası açılmasın.
    if (_openingContentId != null) {
      return;
    }

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _openingContentId = contentId;
    });

    ContentResponse content;
    try {
      content = await _contentService.getById(token, contentId);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _openingContentId = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.contentOpenError)));
      return;
    }

    if (!mounted) return;

    setState(() {
      _openingContentId = null;
    });

    // Mevcut ContentDetailScreen kullanılır; start/complete ilerleme
    // davranışı orada aynen çalışır.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContentDetailScreen(content: content)),
    );

    if (!mounted) return;

    if (task != null) {
      await _completeTaskIfContentCompleted(token, task, contentId);

      if (!mounted) return;
    }

    // İçerik ilerlemesi değişmiş olabilir; dashboard'ı, önerileri ve
    // beceri özetini yenile.
    await Future.wait([
      _loadDashboard(),
      _loadRecommendations(),
      _loadSkills(),
    ]);
  }

  // İçeriğe bağlı görev, içerik tamamlandığında mevcut /complete ile
  // tamamlanır. Aksi halde bu görevler hiç tamamlanamazdı.
  Future<void> _completeTaskIfContentCompleted(
    String token,
    DailyTaskResponse task,
    String contentId,
  ) async {
    if (task.isCompleted) return;

    try {
      final progress = await _contentService.getProgress(token, contentId);

      if (progress['isCompleted'] != true) return;

      await _dailyPlanService.completeTask(token, task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.commonTaskCompleted(task.title)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // Görev tamamlanamazsa akış bozulmaz; dashboard yine yenilenir.
    }
  }

  Future<void> _openQuiz(DailyTaskResponse task) async {
    // Quiz'i backend seçer (task.quizId); gelmezse QuizScreen varsayılan
    // aktif quiz'i açar. QuizScreen içindeki mevcut akış quiz gönderildiğinde
    // bu günlük görevi tamamlar.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          quizId: task.quizId,
          dailyTaskId: task.id,
          isDailyTaskCompleted: task.isCompleted,
        ),
      ),
    );

    if (!mounted) return;

    // Quiz sonucunda günlük görev backend'de tamamlanmış olabilir;
    // dashboard, günlük plan ve (quiz skoru nedeniyle) beceri özetini yenile.
    await Future.wait([_loadDashboard(), _loadSkills()]);
  }

  Widget _buildRecommendationsSection() {
    // Yenileme sırasında mevcut liste korunur; spinner yalnızca liste boşken.
    if (_isLoadingRecommendations && _recommendations.isEmpty) {
      return const _SectionLoader();
    }

    if (_recommendationsError != null) {
      return MenzilimInlineError(
        message: _recommendationsError!,
        onRetry: _loadRecommendations,
      );
    }

    if (_recommendations.isEmpty) {
      return MenzilimInlineEmpty(message: context.l10n.recommendationsEmpty);
    }

    return Column(
      children: _recommendations
          .map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RecommendationCard(
                recommendation: recommendation,
                isOpening: _openingContentId == recommendation.contentId,
                onTap: () => _openContentById(recommendation.contentId),
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'learn':
        return Icons.menu_book_outlined;
      case 'practice':
        return Icons.code_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  void _openDiscover() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DiscoverScreen()));
  }

  void _openProgress() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
  }

  void _openCoach() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AiCoachScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const BrandMark()),
        body: MenzilimErrorView(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });

            _loadDashboard();
          },
        ),
      );
    }

    final dashboard = _dashboard!;
    final dailyPlan = _dailyPlan!;

    final progress = dailyPlan.totalMinutes <= 0
        ? 0.0
        : (dailyPlan.completedMinutes / dailyPlan.totalMinutes).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(),
        actions: [
          IconButton(
            tooltip: l10n.skillsTitle,
            onPressed: _openSkills,
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: l10n.discoverTitle,
            onPressed: _openDiscover,
            icon: const Icon(Icons.explore_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: l10n.settingsTitle,
              onPressed: _openSettings,
              icon: const Icon(Icons.person_outline),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DashboardNavigationBar(
        onDiscover: _openDiscover,
        onSkills: _openSkills,
        onProgress: _openProgress,
        onSettings: _openSettings,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.tablet;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadDashboard(),
                      _loadRecommendations(),
                      _loadSkills(),
                      _loadNews(),
                    ]);
                  },
                  // Tüm bölümler kurulsun (lazy liste değil): dashboard tek
                  // sayfa olarak okunur ve testler bölümleri bulabilir.
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.screen(constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1) Karşılama
                        MenzilimEntrance(
                          order: 0,
                          child: _HeroSection(dashboard: dashboard),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 2) Günlük ilerleme
                        MenzilimEntrance(
                          order: 1,
                          child: _TodayProgressCard(
                            dashboard: dashboard,
                            dailyPlan: dailyPlan,
                            progress: progress,
                            progressPercent: progressPercent,
                            isWide: isWide,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 3) Bugünün yol haritası
                        MenzilimEntrance(
                          order: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MenzilimSectionHeader(
                                title: l10n.dailyPlanTitle,
                                subtitle: l10n.dailyPlanSubtitle,
                                trailingText: l10n.commonMinutesShort(
                                  dailyPlan.totalMinutes,
                                ),
                              ),
                              if (dailyPlan.tasks.isEmpty)
                                MenzilimInlineEmpty(
                                  message: l10n.dailyPlanEmpty,
                                )
                              else
                                ...dailyPlan.tasks.map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: _TaskCard(
                                      icon: _getTaskIcon(task.taskType),
                                      taskType: task.taskType,
                                      title: task.title,
                                      description:
                                          task.description ??
                                          l10n.dailyPlanTaskFallbackDescription,
                                      estimatedMinutes: task.estimatedMinutes,
                                      completed: task.isCompleted,
                                      isCompleting:
                                          _completingTaskId == task.id,
                                      opensContent: _taskOpensContent(task),
                                      onTap: () => _onTaskTap(task),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 4) Alanındaki haberler
                        MenzilimEntrance(order: 3, child: _buildNewsSection()),
                        const SizedBox(height: AppSpacing.section),

                        // 5) Sana özel içerikler
                        MenzilimEntrance(
                          order: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MenzilimSectionHeader(
                                title: l10n.recommendationsTitle,
                                subtitle: l10n.recommendationsSubtitle,
                              ),
                              _buildRecommendationsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 6) Yeteneklerim
                        MenzilimEntrance(
                          order: 5,
                          child: DashboardSkillsSummary(
                            skills: _skills,
                            isLoading: _isLoadingSkills,
                            errorMessage: _skillsError,
                            onRetry: _loadSkills,
                            onViewAll: _openSkills,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 7) Öğrenmeye devam et + 8) AI Koç
                        MenzilimEntrance(
                          order: 6,
                          child: _ActionsSection(
                            isWide: isWide,
                            onContinueLearning: _openDiscover,
                            onAskCoach: _openCoach,
                            onViewProgress: _openProgress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Marka alanı. Logo görseli hazır olduğunda yalnızca bu widget değişir.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo yerleşimi: görsel geldiğinde bu kutunun içine konur.
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.explore_outlined,
            size: 18,
            color: context.colors.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.l10n.appName,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Alt gezinme: ana bölümlere hızlı erişim. Home zaten bu ekran olduğundan
/// seçili kalır; diğerleri mevcut push tabanlı akışla açılır.
class _DashboardNavigationBar extends StatelessWidget {
  final VoidCallback onDiscover;
  final VoidCallback onSkills;
  final VoidCallback onProgress;
  final VoidCallback onSettings;

  const _DashboardNavigationBar({
    required this.onDiscover,
    required this.onSkills,
    required this.onProgress,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 1:
            onDiscover();
          case 2:
            onSkills();
          case 3:
            onProgress();
          case 4:
            onSettings();
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          label: l10n.navDiscover,
        ),
        NavigationDestination(
          icon: const Icon(Icons.insights_outlined),
          label: l10n.navSkills,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          label: l10n.navProgress,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          label: l10n.navProfile,
        ),
      ],
    );
  }
}

/// Karşılama alanı: selam, başlık ve profil bilgileri (rozetler).
class _HeroSection extends StatelessWidget {
  final DashboardResponse dashboard;

  const _HeroSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardGreeting,
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.dashboardHeadline, style: context.textStyles.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.dashboardSubheadline,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Profil bilgileri kompakt rozetler olarak.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            MenzilimChip(
              label: dashboard.profession,
              icon: Icons.work_outline,
              tone: MenzilimChipTone.primary,
            ),
            MenzilimChip(
              label: dashboard.specialization,
              icon: Icons.alt_route_outlined,
              tone: MenzilimChipTone.secondary,
            ),
            MenzilimChip(
              label: l10n.experienceLevelLabel(dashboard.experienceLevel),
              icon: Icons.stairs_outlined,
            ),
            if (dashboard.careerGoal.isNotEmpty)
              MenzilimChip(
                label: dashboard.careerGoal,
                icon: Icons.flag_outlined,
              ),
          ],
        ),
      ],
    );
  }
}

/// Günün hedefi ve ilerleme özeti.
class _TodayProgressCard extends StatelessWidget {
  final DashboardResponse dashboard;
  final DailyPlanResponse dailyPlan;
  final double progress;
  final int progressPercent;
  final bool isWide;

  const _TodayProgressCard({
    required this.dashboard,
    required this.dailyPlan,
    required this.progress,
    required this.progressPercent,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    final stats = [
      _MiniStat(
        icon: Icons.checklist_outlined,
        label: l10n.dashboardTasksShort,
        value: '${dashboard.completedTasks}/${dashboard.totalTasks}',
      ),
      _MiniStat(
        icon: Icons.schedule_outlined,
        label: l10n.progressDuration,
        value: l10n.progressMinutesOfTotal(
          dashboard.completedMinutes,
          dashboard.totalMinutes,
        ),
      ),
      _MiniStat(
        icon: Icons.menu_book_outlined,
        label: l10n.dashboardContent,
        value:
            '${dashboard.completedContentCount}/'
            '${dashboard.completedContentCount + dashboard.inProgressContentCount}',
      ),
    ];

    return MenzilimCard(
      tone: MenzilimCardTone.primary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes,
                size: 20,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.dashboardTodayGoal,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                l10n.commonPercent(progressPercent),
                style: context.textStyles.titleLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            dashboard.specialization,
            style: context.textStyles.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dashboardDailyGoal(dashboard.dailyLearningMinutes),
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimProgressBar(
            value: progress,
            height: 10,
            color: colors.onPrimaryContainer,
            trackColor: colors.onPrimaryContainer.withValues(alpha: 0.18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.dashboardMinutesCompleted(dailyPlan.completedMinutes),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: colors.onPrimaryContainer.withValues(alpha: 0.18)),
          const SizedBox(height: AppSpacing.md),
          if (isWide)
            Row(children: [for (final stat in stats) Expanded(child: stat)])
          else
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.md,
              children: stats,
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onPrimaryContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: context.textStyles.titleSmall?.copyWith(color: color),
            ),
            Text(
              label,
              style: context.textStyles.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Öğrenmeye devam et + AI Koç + ilerleme eylemleri.
class _ActionsSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContinueLearning;
  final VoidCallback onAskCoach;
  final VoidCallback onViewProgress;

  const _ActionsSection({
    required this.isWide,
    required this.onContinueLearning,
    required this.onAskCoach,
    required this.onViewProgress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final coachCard = MenzilimCard(
      onTap: onAskCoach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.coachTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.dashboardCoachPitch,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimButton(
            label: l10n.dashboardAskCoach,
            onPressed: onAskCoach,
            icon: Icons.auto_awesome,
            variant: MenzilimButtonVariant.secondary,
          ),
        ],
      ),
    );

    final learnCard = MenzilimCard(
      onTap: onContinueLearning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: context.colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.discoverTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.dashboardLearnPitch,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MenzilimButton(
            label: l10n.dashboardContinueLearning,
            onPressed: onContinueLearning,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );

    return Column(
      children: [
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: learnCard),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: coachCard),
              ],
            ),
          )
        else ...[
          learnCard,
          const SizedBox(height: AppSpacing.md),
          coachCard,
        ],
        const SizedBox(height: AppSpacing.md),
        MenzilimButton(
          label: l10n.dashboardViewProgress,
          onPressed: onViewProgress,
          icon: Icons.bar_chart_outlined,
          variant: MenzilimButtonVariant.secondary,
        ),
      ],
    );
  }
}

/// Günlük plan görev kartı. Görev tipi renk ve ikonla ayrışır; tamamlanan
/// görevler soluk ve üstü işaretli görünür.
class _TaskCard extends StatelessWidget {
  final IconData icon;
  final String taskType;
  final String title;
  final String description;
  final int estimatedMinutes;
  final bool completed;
  final bool isCompleting;
  final bool opensContent;
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon,
    required this.taskType,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.completed,
    required this.isCompleting,
    required this.onTap,
    this.opensContent = false,
  });

  MenzilimChipTone get _tone => switch (taskType.toLowerCase()) {
    'learn' => MenzilimChipTone.primary,
    'practice' => MenzilimChipTone.secondary,
    'quiz' => MenzilimChipTone.warning,
    _ => MenzilimChipTone.neutral,
  };

  String _typeLabel(BuildContext context) {
    final l10n = context.l10n;

    return switch (taskType.toLowerCase()) {
      'learn' => l10n.taskTypeLearn,
      'practice' => l10n.taskTypePractice,
      'quiz' => l10n.taskTypeQuiz,
      'review' => l10n.taskTypeReview,
      _ => taskType,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.statusColors;

    final iconBackground = completed
        ? status.successContainer
        : colors.surfaceContainerHighest;
    final iconColor = completed ? status.success : colors.onSurfaceVariant;

    return Opacity(
      opacity: completed ? 0.72 : 1,
      child: MenzilimCard(
        onTap: completed || isCompleting ? null : onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MenzilimChip(label: _typeLabel(context), tone: _tone),
                      MenzilimChip(
                        label: context.l10n.commonMinutesShort(
                          estimatedMinutes,
                        ),
                        icon: Icons.schedule_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: context.textStyles.titleMedium?.copyWith(
                      decoration: completed ? TextDecoration.lineThrough : null,
                      decorationColor: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (opensContent && !completed) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.taskGoToContent,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (isCompleting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (completed)
              Icon(Icons.check_circle, color: status.success)
            else if (opensContent)
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant)
            else
              Icon(Icons.circle_outlined, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Öneri kartı: durum rozeti, başlık, açıklama, gerekçe ve eylem.
class _RecommendationCard extends StatelessWidget {
  final ContentRecommendationResponse recommendation;
  final bool isOpening;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.isOpening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isStarted = recommendation.isStarted;
    final description = recommendation.description;

    return MenzilimCard(
      onTap: isOpening ? null : onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isStarted
                  ? Icons.play_circle_outline
                  : Icons.auto_stories_outlined,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MenzilimChip(
                  label: isStarted
                      ? l10n.recommendationInProgress
                      : l10n.recommendationNew,
                  tone: isStarted
                      ? MenzilimChipTone.secondary
                      : MenzilimChipTone.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  recommendation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (recommendation.recommendationReason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          recommendation.recommendationReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isStarted
                          ? l10n.commonContinue
                          : l10n.recommendationStart,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.arrow_forward, size: 16, color: colors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (isOpening)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
