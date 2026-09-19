import 'package:flutter/material.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openNewsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsScreen(
          newsService: _newsService,
          openLink: _openNewsLink,
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    final colors = Theme.of(context).colorScheme;

    Widget body;

    if (_isLoadingNews) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_newsError != null) {
      body = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(_newsError!),
            TextButton(
              onPressed: _loadNews,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    } else if (_news.isEmpty) {
      body = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(context.l10n.newsEmpty),
      );
    } else {
      body = Column(
        children: _news
            .take(_dashboardNewsCount)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.newsSectionTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_news.isNotEmpty)
              TextButton(
                onPressed: _openNewsScreen,
                child: Text(context.l10n.newsViewAll),
              ),
          ],
        ),
        const SizedBox(height: 16),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SkillsScreen(),
      ),
    );
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

      final recommendations =
          await _contentService.getRecommendations(token);

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

      final results = await Future.wait([
        _dashboardService.getDashboard(token),
        _dailyPlanService.getToday(token),
      ]);

      if (!mounted) return;

      setState(() {
        _dashboard = results[0] as DashboardResponse;
        _dailyPlan = results[1] as DailyPlanResponse;
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
      final updatedPlan =
          await _dailyPlanService.completeTask(
        token,
        task.id,
      );

      if (!mounted) return;

      setState(() {
        _dailyPlan = updatedPlan;
        _completingTaskId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.commonTaskCompleted(task.title),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _completingTaskId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.dashboardTaskCompleteError,
          ),
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.contentOpenError),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _openingContentId = null;
    });

    // Mevcut ContentDetailScreen kullanılır; start/complete ilerleme
    // davranışı orada aynen çalışır.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(content: content),
      ),
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
      final progress =
          await _contentService.getProgress(token, contentId);

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
    await Future.wait([
      _loadDashboard(),
      _loadSkills(),
    ]);
  }

  Widget _buildRecommendationsSection() {
    // Yenileme sırasında mevcut liste korunur; spinner yalnızca liste boşken.
    if (_isLoadingRecommendations && _recommendations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_recommendationsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(_recommendationsError!),
            TextButton(
              onPressed: _loadRecommendations,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          context.l10n.recommendationsEmpty,
        ),
      );
    }

    return Column(
      children: _recommendations
          .map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _RecommendationCard(
                recommendation: recommendation,
                isOpening:
                    _openingContentId == recommendation.contentId,
                onTap: () =>
                    _openContentById(recommendation.contentId),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
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

                    _loadDashboard();
                  },
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dashboard = _dashboard!;
    final dailyPlan = _dailyPlan!;

    final progress = dailyPlan.totalMinutes <= 0 ? 0.0 : (dailyPlan.completedMinutes / dailyPlan.totalMinutes).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.appName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.skillsTitle,
                        onPressed: _openSkills,
                        icon: const Icon(
                          Icons.insights_outlined,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.discoverTitle,
                        onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiscoverScreen(),
                          ),
                        );
                      },
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profil simgesi ayarlara (dil/tema) götürür.
                      Tooltip(
                        message: l10n.settingsTitle,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _openSettings,
                          child: const CircleAvatar(
                            child: Icon(
                              Icons.person_outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  Text(
                    l10n.dashboardGreeting,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    l10n.dashboardHeadline,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    l10n.dashboardSubheadline,
                    style: TextStyle(
                      fontSize: 17,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              color: context.colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.dashboardTodayGoal,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          dashboard.specialization,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          l10n.dashboardDailyGoal(
                            dashboard.dailyLearningMinutes,
                          ),
                          style: TextStyle(
                            color: context.colors.onPrimaryContainer,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.dashboardMinutesCompleted(
                                  dailyPlan.completedMinutes,
                                ),
                              ),
                            ),
                            Text(
                              l10n.commonPercent(progressPercent),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.dashboardProfileTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _ProfileRow(
                          title: l10n.profileProfession,
                          value: dashboard.profession,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: l10n.profileSpecialization,
                          value: dashboard.specialization,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: l10n.profileLevel,
                          value: l10n.experienceLevelLabel(
                            dashboard.experienceLevel,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: l10n.profileCareerGoal,
                          value: dashboard.careerGoal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.dashboardProgressTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Günlük Plan İlerlemesi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dashboardDailyPlan,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: LinearProgressIndicator(
                            value: dashboard.totalMinutes <= 0
                                ? 0.0
                                : (dashboard.completedMinutes /
                                        dashboard.totalMinutes)
                                    .clamp(0.0, 1.0),
                            minHeight: 12,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.dashboardTasksCompleted(
                                  dashboard.completedTasks,
                                  dashboard.totalTasks,
                                ),
                                style: TextStyle(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              l10n.commonPercent(
                                dashboard.dailyProgressPercent.round(),
                              ),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          l10n.dashboardMinutesOfTotal(
                            dashboard.completedMinutes,
                            dashboard.totalMinutes,
                          ),
                          style: TextStyle(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // İçerik İlerlemesi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dashboardContent,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: context.statusColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dashboardContentCompleted(
                                dashboard.completedContentCount,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(
                              Icons.circle_outlined,
                              size: 18,
                              color: context.statusColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dashboardContentInProgress(
                                dashboard.inProgressContentCount,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Beceri Özeti
                  DashboardSkillsSummary(
                    skills: _skills,
                    isLoading: _isLoadingSkills,
                    errorMessage: _skillsError,
                    onRetry: _loadSkills,
                    onViewAll: _openSkills,
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.dailyPlanTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        l10n.commonMinutesShort(dailyPlan.totalMinutes),
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (dailyPlan.tasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.colors.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        l10n.dailyPlanEmpty,
                      ),
                    )
                  else
                    ...dailyPlan.tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: _TaskCard(
                          icon: _getTaskIcon(task.taskType),
                          title: task.title,
                          description:
                              task.description ??
                              l10n.dailyPlanTaskFallbackDescription,
                          estimatedMinutes:
                              task.estimatedMinutes,
                          completed: task.isCompleted,
                          isCompleting:
                              _completingTaskId == task.id,
                          opensContent: _taskOpensContent(task),
                          onTap: () => _onTaskTap(task),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Text(
                    l10n.recommendationsTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildRecommendationsSection(),

                  const SizedBox(height: 32),

                  _buildNewsSection(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiscoverScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward,
                      ),
                      label: Text(
                        l10n.dashboardContinueLearning,
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AiCoachScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.auto_awesome,
                      ),
                      label: Text(
                        l10n.dashboardAskCoach,
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProgressScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.bar_chart_outlined,
                      ),
                      label: Text(
                        l10n.dashboardViewProgress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            title,
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int estimatedMinutes;
  final bool completed;
  final bool isCompleting;
  final bool opensContent;
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.completed,
    required this.isCompleting,
    required this.onTap,
    this.opensContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: completed || isCompleting ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    description,
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    context.l10n.commonMinutes(estimatedMinutes),
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (opensContent && !completed) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.taskGoToContent,
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            if (isCompleting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else if (completed)
              Icon(
                Icons.check_circle,
                color: context.statusColors.success,
              )
            else if (opensContent)
              const Icon(Icons.chevron_right)
            else
              const Icon(Icons.circle_outlined),
          ],
        ),
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    final isStarted = recommendation.isStarted;
    final description = recommendation.description;

    return InkWell(
      onTap: isOpening ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isStarted
                    ? Icons.play_circle_outline
                    : Icons.auto_stories_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isStarted
                          ? colorScheme.secondaryContainer
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isStarted
                          ? context.l10n.recommendationInProgress
                          : context.l10n.recommendationNew,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    recommendation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (description != null &&
                      description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  if (recommendation
                      .recommendationReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recommendation.recommendationReason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isStarted
                            ? context.l10n.commonContinue
                            : context.l10n.recommendationStart,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            if (isOpening)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
