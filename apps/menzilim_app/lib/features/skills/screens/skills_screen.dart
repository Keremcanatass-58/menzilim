import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/skill_progress_response.dart';
import '../services/skill_service.dart';

class SkillsScreen extends StatefulWidget {
  // Testlerde sahte servis verilebilir; normalde gerçek API kullanılır.
  final SkillService? skillService;

  const SkillsScreen({
    super.key,
    this.skillService,
  });

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late final SkillService _skillService =
      widget.skillService ?? SkillService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  List<SkillProgressResponse> _skills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      final skills = await _skillService.getMySkills(token);

      if (!mounted) return;

      setState(() {
        _skills = skills;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Yetenekler yüklenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeteneklerim',
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

                  _loadSkills();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_skills.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSkills,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.insights_outlined,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Uzmanlık alanın için henüz yetenek bulunmuyor.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final startedCount =
        _skills.where((skill) => skill.progressPercent > 0).length;

    return RefreshIndicator(
      onRefresh: _loadSkills,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Yetenek haritan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_skills.length} yetenekten $startedCount tanesinde '
                'ilerleme kaydettin.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ..._skills.map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SkillCard(skill: skill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillProgressResponse skill;

  const _SkillCard({
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.skillName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (skill.category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          skill.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '%${skill.progressPercent}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: skill.progressPercent > 0
                      ? colorScheme.primary
                      : Colors.grey.shade600,
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
              value: skill.progressPercent / 100,
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _StatItem(
                icon: Icons.menu_book_outlined,
                label: 'İçerik: ${skill.completedContentCount} / '
                    '${skill.totalContentCount}',
              ),
              _StatItem(
                icon: Icons.quiz_outlined,
                label: 'Quiz: ${skill.attemptedQuizCount} / '
                    '${skill.totalQuizCount}',
              ),
              if (skill.inProgressContentCount > 0)
                _StatItem(
                  icon: Icons.timelapse_outlined,
                  label: 'Devam eden: ${skill.inProgressContentCount}',
                ),
              if (skill.bestQuizScore != null)
                _StatItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'En iyi skor: %${skill.bestQuizScore}',
                ),
              if (skill.latestQuizScore != null)
                _StatItem(
                  icon: Icons.history,
                  label: 'Son skor: %${skill.latestQuizScore}',
                ),
            ],
          ),

          if (!skill.hasLearningMaterial) ...[
            const SizedBox(height: 12),
            Text(
              'Bu yetenek için henüz içerik veya quiz eklenmedi.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        // Çok dar ekranda etiket taşmak yerine alt satıra geçer.
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
