import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/localization/l10n.dart';
import '../../ai_coach/screens/ai_coach_screen.dart';
import '../../content/screens/discover_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../projects/screens/project_screen.dart';

/// Uygulamanın kalıcı kabuğu: sekmeler arasında geçişte ekran durumu korunur
/// (IndexedStack). Sekmeler Navigator.push ile taklit edilmez.
class MainShell extends StatefulWidget {
  /// Testlerde açılış sekmesi verilebilir.
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  /// Proje her değiştiğinde artar; Bugün sekmesi bunu görünce yeniler.
  int _projectVersion = 0;

  void _select(int index) {
    if (index == _index) return;

    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final pages = [
      DashboardScreen(
        embedded: true,
        onNavigate: _select,
        refreshToken: _projectVersion,
        onProjectChanged: () => setState(() => _projectVersion++),
      ),
      ProjectScreen(
        onGoToToday: () => _select(0),
        onProjectChanged: () => setState(() => _projectVersion++),
        refreshToken: _projectVersion,
      ),
      const DiscoverScreen(),
      const AiCoachScreen(),
      const ProfileScreen(),
    ];
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.today_outlined),
        selectedIcon: const Icon(Icons.today),
        label: l10n.navToday,
      ),
      NavigationDestination(
        icon: const Icon(Icons.route_outlined),
        selectedIcon: const Icon(Icons.route),
        label: l10n.navPath,
      ),
      NavigationDestination(
        icon: const Icon(Icons.explore_outlined),
        selectedIcon: const Icon(Icons.explore),
        label: l10n.navDiscover,
      ),
      NavigationDestination(
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome),
        label: l10n.navCoach,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n.navProfile,
      ),
    ];

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.6,
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: pages),
                ),
              ],
            )
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: destinations,
            ),
    );
  }
}
