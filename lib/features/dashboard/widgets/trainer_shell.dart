import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';

class TrainerShell extends ConsumerWidget {
  final Widget child;

  const TrainerShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/trainer/dashboard')) return 0;
    if (location.startsWith('/trainer/clients')) return 1;
    if (location.startsWith('/trainer/check-ins')) return 2;
    if (location.startsWith('/trainer/calendar')) return 3;
    if (location.startsWith('/trainer/profile')) return 4;
    if (location.startsWith('/trainer/settings')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 6) {
            // Mode switch — router handles the redirect automatically
            ref.read(modeSwitchProvider.notifier).switchMode();
            return;
          }
          switch (i) {
            case 0:
              context.go('/trainer/dashboard');
              break;
            case 1:
              context.go('/trainer/clients');
              break;
            case 2:
              context.go('/trainer/check-ins');
              break;
            case 3:
              context.go('/trainer/calendar');
              break;
            case 4:
              context.go('/trainer/profile');
              break;
            case 5:
              context.go('/trainer/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Check-Ins',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Personal',
          ),
        ],
      ),
    );
  }
}
