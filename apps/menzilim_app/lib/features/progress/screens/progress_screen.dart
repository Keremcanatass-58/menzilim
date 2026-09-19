import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/progress_response.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  final ProgressService? progressService;

  const ProgressScreen({
    super.key,
    this.progressService,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressService _progressService =
      widget.progressService ?? ProgressService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  ProgressResponse? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final progress = await _progressService.getMyProgress(token);

      if (!mounted) return;

      setState(() {
        _progress = progress;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'İlerleme yüklenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Genel İlerleme',
          style: TextStyle(
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
                  _loadProgress();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_progress == null) {
      return const Center(
        child: Text('İlerleme verisi bulunamadı.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildTodaySection(),
            const SizedBox(height: 24),
            _buildContentSection(),
            const SizedBox(height: 24),
            _buildQuizSection(),
            const SizedBox(height: 24),
            _buildSkillsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overview = _progress!.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genel Bakış',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.check_circle_outline,
                label: 'Tamamlanan Görev',
                value: overview.completedTaskCount.toString(),
                subtitle: 'toplam',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.timer_outlined,
                label: 'Öğrenme Süresi',
                value: '${overview.estimatedLearningMinutes}',
                subtitle: 'dakika',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.calendar_today_outlined,
                label: 'Tamamlanan Plan',
                value: overview.completedPlanCount.toString(),
                subtitle: 'plan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OverviewCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Aktif Gün',
                value: overview.activeDayCount.toString(),
                subtitle: 'gün',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final today = _progress!.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bugün',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      today.hasPlan ? 'Bugünkü Plan' : 'Bugün Plan Yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: today.hasPlan ? Colors.blue : Colors.grey,
                      ),
                    ),
                    Text(
                      '${today.progressPercent}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: today.progressPercent > 0
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  child: LinearProgressIndicator(
                    value: today.totalMinutes > 0
                        ? today.completedMinutes / today.totalMinutes
                        : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TodayStat(
                      icon: Icons.task_outlined,
                      label: 'Görevler',
                      value: '${today.completedTasks}/${today.totalTasks}',
                    ),
                    _TodayStat(
                      icon: Icons.timer,
                      label: 'Süre',
                      value:
                          '${today.completedMinutes}/${today.totalMinutes} dk',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    final content = _progress!.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İçerik İlerlemesi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ContentCard(
                icon: Icons.check_circle,
                color: Colors.green,
                label: 'Tamamlanan',
                value: content.completedCount.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContentCard(
                icon: Icons.play_circle_outline,
                color: Colors.orange,
                label: 'Devam Eden',
                value: content.inProgressCount.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizSection() {
    final quiz = _progress!.quiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz İlerlemesi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quiz Özeti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (quiz.attemptCount > 0)
                      Text(
                        '${quiz.attemptCount} deneme',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (quiz.attemptCount == 0)
                  const Text(
                    'Henüz quiz denemesi yapmadın.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _QuizStat(
                          icon: Icons.emoji_events_outlined,
                          label: 'En İyi Skor',
                          value: quiz.bestScore != null
                              ? '%${quiz.bestScore}'
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuizStat(
                          icon: Icons.calculate_outlined,
                          label: 'Ortalama',
                          value: quiz.averageScore != null
                              ? '%${quiz.averageScore}'
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuizStat(
                          icon: Icons.history,
                          label: 'Son Skor',
                          value: quiz.latestScore != null
                              ? '%${quiz.latestScore}'
                              : '-',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skills = _progress!.skills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beceriler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${skills.totalCount} beceriden ${skills.startedCount} tanesinde ilerleme var',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (skills.strongest.isNotEmpty) ...[
          const Text(
            'En Güçlü Beceriler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...skills.strongest.map((skill) => _SkillCard(
                skill: skill,
                color: Colors.green,
              )),
          const SizedBox(height: 24),
        ],
        if (skills.focus.isNotEmpty) ...[
          const Text(
            'Odak Beceriler (İlerlemesi Düşük)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...skills.focus.map((skill) => _SkillCard(
                skill: skill,
                color: Colors.orange,
              )),
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TodayStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ContentCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuizStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.purple.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.purple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillProgressSnapshot skill;
  final Color color;

  const _SkillCard({
    required this.skill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.skillName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (skill.category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      skill.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${skill.progressPercent}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 1),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      value: skill.progressPercent / 100,
                      minHeight: 3,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}