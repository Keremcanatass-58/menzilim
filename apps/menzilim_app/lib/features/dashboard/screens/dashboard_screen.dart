import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/localization/domain_labels.dart';
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
import '../../progress/screens/progress_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../news/models/news_item.dart';
import '../../news/screens/news_screen.dart';
import '../../news/services/news_link_opener.dart';
import '../../news/services/news_service.dart';
import '../../news/widgets/news_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../projects/models/user_project.dart';
import '../../projects/screens/project_screen.dart';
import '../../projects/services/project_service.dart';
import '../../projects/widgets/path_roadmap.dart';
import '../../projects/screens/project_step_detail_screen.dart';
import '../../projects/widgets/project_card.dart';
import '../../skills/models/skill_gap_response.dart';
import '../../skills/widgets/skill_gap_summary.dart';
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
  final ProjectService? projectService;

  /// MainShell içindeyken kendi alt navigasyonunu çizmez.
  final bool embedded;

  /// Sekme değiştirme isteği (Yolum, Keşfet, Koç, Profil).
  final void Function(int index)? onNavigate;

  /// Değeri değişince ekran yenilenir (ör. projede adım tamamlandı).
  final int refreshToken;

  /// Bu ekranda proje ilerlediğinde çağrılır; kabuk diğer sekmeleri tazeler.
  final VoidCallback? onProjectChanged;

  const DashboardScreen({
    super.key,
    this.dashboardService,
    this.dailyPlanService,
    this.contentService,
    this.skillService,
    this.newsService,
    this.openNewsLink,
    this.projectService,
    this.embedded = false,
    this.onNavigate,
    this.refreshToken = 0,
    this.onProjectChanged,
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

  late final ProjectService _projectService =
      widget.projectService ?? ProjectService(ApiClient());

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
  static const int _dashboardNewsCount = 2;
  List<NewsItem> _news = [];
  bool _isLoadingNews = true;
  String? _newsError;

  // Dashboard'daki öneri sayısı sınırlıdır; tamamı Keşfet'te.
  static const int _dashboardRecommendationCount = 2;

  // Living Project de bağımsız yüklenir.
  UserProject? _project;
  bool _isLoadingProject = true;

  // Hedefe göre beceri durumu (özet olarak gösterilir).
  SkillGapResponse? _skillGap;
  bool _isLoadingSkillGap = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRecommendations();
    _loadSkills();
    _loadNews();
    _loadProject();
    _loadSkillGap();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Başka sekmede proje ilerledi: bugün ve proje verisi tazelenir.
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadProject();
      _loadDashboard();
      _loadSkills();
      _loadSkillGap();
    }
  }

  Future<void> _loadSkillGap() async {
    if (mounted && !_isLoadingSkillGap) {
      setState(() {
        _isLoadingSkillGap = true;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final gap = await _skillService.getMySkillGap(token);

      if (!mounted) return;

      setState(() {
        _skillGap = gap;
        _isLoadingSkillGap = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Beceri özeti alınamazsa dashboard çalışmaya devam eder.
      setState(() {
        _skillGap = null;
        _isLoadingSkillGap = false;
      });
    }
  }

  Future<void> _loadProject() async {
    if (mounted && !_isLoadingProject) {
      setState(() {
        _isLoadingProject = true;
      });
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final projects = await _projectService.getMyProjects(token);

      if (!mounted) return;

      setState(() {
        _project = projects.isEmpty ? null : projects.first;
        _isLoadingProject = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Proje yoksa/yüklenemezse dashboard çalışmaya devam eder.
      setState(() {
        _project = null;
        _isLoadingProject = false;
      });
    }
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
    if (task.isProjectStep) {
      _openProjectStep(task);
    } else if (_taskOpensContent(task)) {
      _openContentById(task.contentId!, task: task);
    } else if (task.taskType.toLowerCase() == 'quiz') {
      _openQuiz(task);
    } else {
      _completeTask(task);
    }
  }

  /// Projeye bağlı görev: adımın detayı açılır. Adım verisi yüklenmemişse
  /// önce proje tazelenir.
  Future<void> _openProjectStep(DailyTaskResponse task) async {
    var project = _project;

    if (project == null ||
        !project.steps.any((s) => s.id == task.userProjectStepId)) {
      await _loadProject();
      project = _project;
    }

    if (!mounted || project == null) return;

    final step = project.steps
        .where((s) => s.id == task.userProjectStepId)
        .firstOrNull;

    if (step == null) {
      // Adım bulunamazsa görev eski davranışla tamamlanır.
      _completeTask(task);
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectStepDetailScreen(
          project: project!,
          step: step,
          quizId: task.quizId,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      widget.onProjectChanged?.call();

      await Future.wait([
        _loadProject(),
        _loadDashboard(),
        _loadSkills(),
        _loadSkillGap(),
      ]);
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
          .take(_dashboardRecommendationCount)
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
    if (widget.onNavigate != null) {
      widget.onNavigate!(2);
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DiscoverScreen()));
  }

  void _openProgress() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
  }

  /// Kabuk içindeyken sekme değişir; tek başına açıldığında ekran push edilir.
  void _openProject() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(1);
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProjectScreen()));
  }

  void _openPath() => _openProject();

  void _openProfile() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(4);
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: l10n.profileScreenTitle,
              onPressed: _openProfile,
              icon: const Icon(Icons.person_outline),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : _DashboardNavigationBar(
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
                      _loadProject(),
                      _loadSkillGap(),
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
                        // Karşılama: kısa tutulur, asıl ağırlık "Bugün"dedir.
                        MenzilimEntrance(
                          order: 0,
                          child: _HeroSection(dashboard: dashboard),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 1) BUGÜN
                        MenzilimEntrance(
                          order: 1,
                          child: _buildTodaySection(dailyPlan, dashboard),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        MenzilimEntrance(
                          order: 2,
                          child: _TodayProgressCard(
                            dashboard: dashboard,
                            dailyPlan: dailyPlan,
                            progress: progress,
                            progressPercent: progressPercent,
                            isWide: isWide,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 2) PROJEM
                        MenzilimEntrance(
                          order: 3,
                          child: _buildProjectSection(),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // 3) YOLUM
                        MenzilimEntrance(
                          order: 4,
                          child: _buildPathSection(dashboard),
                        ),
                        const SizedBox(height: AppSpacing.section),

                        // Keşif: haber ve öneriler ana odak değildir.
                        MenzilimEntrance(
                          order: 5,
                          child: _buildDiscoverySection(),
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

  /// BUGÜN: tek güçlü aksiyon. Ana görev öne çıkar, kalanlar altında kalır.
  Widget _buildTodaySection(
    DailyPlanResponse dailyPlan,
    DashboardResponse dashboard,
  ) {
    final l10n = context.l10n;
    final tasks = dailyPlan.tasks;

    if (tasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenzilimSectionHeader(
            title: l10n.dailyPlanTitle,
            subtitle: l10n.dailyPlanSubtitle,
          ),
          MenzilimInlineEmpty(
            message: l10n.dailyPlanEmpty,
            hint: l10n.projectEmptyHint,
          ),
        ],
      );
    }

    final pending = tasks.where((task) => !task.isCompleted).toList();
    final mainTask = pending.isEmpty ? null : pending.first;
    final rest = mainTask == null
        ? tasks
        : tasks.where((task) => task.id != mainTask.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(
          title: mainTask == null ? l10n.todayAllDone : l10n.todayFocusTitle,
          subtitle: mainTask == null
              ? l10n.todayAllDoneHint
              : l10n.dailyPlanSubtitle,
          trailingText: l10n.commonMinutesShort(dailyPlan.totalMinutes),
        ),
        if (mainTask != null)
          _TaskCard(
            icon: _getTaskIcon(mainTask.taskType),
            taskType: mainTask.taskType,
            title: mainTask.title,
            description: mainTask.description ??
                l10n.dailyPlanTaskFallbackDescription,
            estimatedMinutes: mainTask.estimatedMinutes,
            completed: mainTask.isCompleted,
            isCompleting: _completingTaskId == mainTask.id,
            opensContent: _taskOpensContent(mainTask),
            emphasized: true,
            actionLabel: l10n.todayStart,
            // Proje adımıysa hangi adım olduğu ve hedefe katkısı gösterilir.
            projectStepOrder: mainTask.projectStepOrder,
            skillName: mainTask.skillName,
            footnote: mainTask.isProjectStep
                ? l10n.todayProjectHint(dashboard.careerGoal)
                : null,
            onTap: () => _onTaskTap(mainTask),
          ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.todayOtherSteps,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rest.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TaskCard(
                icon: _getTaskIcon(task.taskType),
                taskType: task.taskType,
                title: task.title,
                description:
                    task.description ?? l10n.dailyPlanTaskFallbackDescription,
                estimatedMinutes: task.estimatedMinutes,
                completed: task.isCompleted,
                isCompleting: _completingTaskId == task.id,
                opensContent: _taskOpensContent(task),
                onTap: () => _onTaskTap(task),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// PROJEM: öğrenmenin dönüştüğü ürün.
  Widget _buildProjectSection() {
    final l10n = context.l10n;

    Widget body;

    if (_isLoadingProject) {
      body = const _SectionLoader();
    } else if (_project == null) {
      body = MenzilimInlineEmpty(
        message: l10n.projectEmptyTitle,
        hint: l10n.projectEmptyHint,
      );
    } else {
      body = ProjectCard(project: _project!, onOpen: _openProject);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(
          title: l10n.dashboardProjectTitle,
          subtitle: l10n.dashboardProjectSubtitle,
          actionLabel: _project == null ? null : l10n.dashboardViewAll,
          onAction: _project == null ? null : _openProject,
        ),
        body,
      ],
    );
  }

  /// YOLUM: hedef, mevcut faz ve beceri özeti.
  Widget _buildPathSection(DashboardResponse dashboard) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MenzilimSectionHeader(
          title: l10n.dashboardPathTitle,
          subtitle: l10n.dashboardPathSubtitle,
          actionLabel: l10n.dashboardViewAll,
          onAction: _openPath,
        ),
        if (_project != null) ...[
          PathRoadmap(project: _project!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!_isLoadingSkillGap && _skillGap != null) ...[
          SkillGapSummary(
            gap: _skillGap!,
            onViewPath: _openPath,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        DashboardSkillsSummary(
          skills: _skills,
          isLoading: _isLoadingSkills,
          errorMessage: _skillsError,
          onRetry: _loadSkills,
          onViewAll: _openSkills,
        ),
      ],
    );
  }

  /// Keşif: alanındaki gelişmeler ve öneriler (ikincil ağırlık).
  Widget _buildDiscoverySection() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNewsSection(),
        const SizedBox(height: AppSpacing.xl),
        MenzilimSectionHeader(
          title: l10n.recommendationsTitle,
          subtitle: l10n.recommendationsSubtitle,
          actionLabel: l10n.dashboardViewAll,
          onAction: _openDiscover,
        ),
        _buildRecommendationsSection(),
      ],
    );
  }
}

/// Uygulama çubuğundaki marka alanı: sembol + MENZİLİM yazısı.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const MenzilimLogo(markSize: 30);
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

  /// Günün ana görevi: daha güçlü görsel ağırlık ve tek net eylem.
  final bool emphasized;
  final String? actionLabel;

  /// Proje adımıysa: kaçıncı adım, hangi beceri ve hedefe katkısı.
  final int? projectStepOrder;
  final String? skillName;
  final String? footnote;

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
    this.emphasized = false,
    this.actionLabel,
    this.projectStepOrder,
    this.skillName,
    this.footnote,
  });

  MenzilimChipTone get _tone => switch (taskType.toLowerCase()) {
    'learn' => MenzilimChipTone.primary,
    'practice' => MenzilimChipTone.secondary,
    'quiz' => MenzilimChipTone.warning,
    _ => MenzilimChipTone.neutral,
  };

  String _typeLabel(BuildContext context) {
    return context.taskTypeLabel(taskType);
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
        tone: emphasized && !completed
            ? MenzilimCardTone.primary
            : MenzilimCardTone.surface,
        padding: EdgeInsets.all(
          emphasized ? AppSpacing.xl : AppSpacing.lg,
        ),
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
                      if (projectStepOrder != null)
                        MenzilimChip(
                          label: context.l10n.stepDetailOrder(
                            projectStepOrder!,
                          ),
                          icon: Icons.flag_outlined,
                        ),
                      if (skillName != null)
                        MenzilimChip(
                          label: skillName!,
                          icon: Icons.bolt_outlined,
                          tone: MenzilimChipTone.secondary,
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
                  if (footnote != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      footnote!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (emphasized && !completed && actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    MenzilimButton(
                      label: actionLabel!,
                      icon: Icons.play_arrow_rounded,
                      isLoading: isCompleting,
                      onPressed: onTap,
                    ),
                  ] else if (opensContent && !completed) ...[
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
