import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/dashboard_response.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService =
      DashboardService(ApiClient());

  final TokenStorage _tokenStorage = TokenStorage();

  DashboardResponse? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

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

      final dashboard =
          await _dashboardService.getDashboard(token);

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Dashboard bilgileri yüklenemedi.';
        _isLoading = false;
      });
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
                        onPressed: () {},
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

                        const ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                          child: LinearProgressIndicator(
                            value: 0,
                            minHeight: 10,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('0 dakika tamamlandı'),
                            Text(
                              '%0',
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
                    'Bugünün Yol Haritası',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _TaskCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Bugünün konusu',
                    description:
                        'Kişiselleştirilmiş öğrenme planın hazırlanacak.',
                    completed: false,
                  ),

                  const SizedBox(height: 12),

                  _TaskCard(
                    icon: Icons.code_outlined,
                    title: 'Uygulama',
                    description:
                        'Öğrendiğin konuyu bir projede uygula.',
                    completed: false,
                  ),

                  const SizedBox(height: 12),

                  _TaskCard(
                    icon: Icons.quiz_outlined,
                    title: 'Mini Test',
                    description:
                        'Bugünkü konuyla ilgili bilgini test et.',
                    completed: false,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {},
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
  final bool completed;

  const _TaskCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              ],
            ),
          ),
          Icon(
            completed
                ? Icons.check_circle
                : Icons.circle_outlined,
          ),
        ],
      ),
    );
  }
}
