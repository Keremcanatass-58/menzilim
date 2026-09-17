import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../daily_plan/models/daily_plan_response.dart';
import '../../daily_plan/services/daily_plan_service.dart';
import '../models/dashboard_response.dart';
import '../services/dashboard_service.dart';
import '../../content/screens/discover_screen.dart';
import '../../quiz/screens/quiz_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService =
      DashboardService(ApiClient());

  final DailyPlanService _dailyPlanService =
      DailyPlanService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  DashboardResponse? _dashboard;
  DailyPlanResponse? _dailyPlan;

  bool _isLoading = true;
  String? _errorMessage;
  String? _completingTaskId;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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
        _errorMessage = 'Dashboard bilgileri yüklenemedi.';
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
            '${task.title} tamamlandı! 🎉',
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
        const SnackBar(
          content: Text(
            'Görev tamamlanırken bir hata oluştu.',
          ),
        ),
      );
    }
  }

  void _onTaskTap(DailyTaskResponse task) {
    if (task.taskType.toLowerCase() == 'quiz') {
      _openQuiz(task);
    } else {
      _completeTask(task);
    }
  }

  Future<void> _openQuiz(DailyTaskResponse task) async {
    // Aktif quiz'i getirmek için quizId verilmiyor; QuizScreen içindeki
    // mevcut akış quiz gönderildiğinde bu günlük görevi tamamlar.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          dailyTaskId: task.id,
          isDailyTaskCompleted: task.isCompleted,
        ),
      ),
    );

    if (!mounted) return;

    // Quiz sonucunda günlük görev backend'de tamamlanmış olabilir;
    // dashboard ve günlük plan durumunu yenile.
    await _loadDashboard();
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
                  child: const Text('Tekrar Dene'),
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
                      const Text(
                        'MENZİLİM',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
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
                      const CircleAvatar(
                        child: Icon(
                          Icons.person_outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  const Text(
                    'Merhaba 👋',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Gelişim yolculuğuna devam et.',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Bugün kendin için bir adım daha at.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey.shade700,
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
                        const Row(
                          children: [
                            Icon(Icons.track_changes),
                            SizedBox(width: 10),
                            Text(
                              'Bugünkü Hedef',
                              style: TextStyle(
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
                          'Günlük öğrenme hedefin: '
                          '${dashboard.dailyLearningMinutes} dakika',
                          style: TextStyle(
                            color: Colors.grey.shade700,
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
                            Text(
                              '${dailyPlan.completedMinutes} '
                              'dakika tamamlandı',
                            ),
                            Text(
                              '%$progressPercent',
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

                  const Text(
                    'Profilin',
                    style: TextStyle(
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
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _ProfileRow(
                          title: 'Meslek',
                          value: dashboard.profession,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: 'Uzmanlık',
                          value: dashboard.specialization,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: 'Seviye',
                          value: dashboard.experienceLevel,
                        ),
                        const SizedBox(height: 14),
                        _ProfileRow(
                          title: 'Kariyer hedefi',
                          value: dashboard.careerGoal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'İlerleme',
                    style: TextStyle(
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
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Günlük Plan',
                              style: TextStyle(
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
                            Text(
                              '${dashboard.completedTasks} / '
                              '${dashboard.totalTasks} '
                              'görev tamamlandı',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '%${dashboard.dailyProgressPercent.round()}',
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
                          '${dashboard.completedMinutes} / '
                          '${dashboard.totalMinutes} dakika',
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'İçerik',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${dashboard.completedContentCount} '
                              'tamamlandı',
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
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${dashboard.inProgressContentCount} '
                              'devam ediyor',
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bugünün Yol Haritası',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${dailyPlan.totalMinutes} dk',
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Bugün için henüz görev bulunmuyor.',
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
                              'Bugünkü gelişim planındaki görev.',
                          estimatedMinutes:
                              task.estimatedMinutes,
                          completed: task.isCompleted,
                          isCompleting:
                              _completingTaskId == task.id,
                          onTap: () => _onTaskTap(task),
                        ),
                      ),
                    ),

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
                      label: const Text(
                        'Öğrenmeye Devam Et',
                        style: TextStyle(
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
              color: Colors.grey.shade600,
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
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.completed,
    required this.isCompleting,
    required this.onTap,
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
            color: Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
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
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$estimatedMinutes dakika',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
            else
              Icon(
                completed
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
          ],
        ),
      ),
    );
  }
}
