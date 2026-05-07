import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';

class ClientShell extends ConsumerWidget {
  final Widget child;

  const ClientShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/client/dashboard')) return 0;
    if (location.startsWith('/client/workout')) return 1;
    if (location.startsWith('/client/progress')) return 2;
    if (location.startsWith('/client/trainer')) return 3;
    if (location.startsWith('/client/check-in')) return 4;
    if (location.startsWith('/client/explore')) return 5;
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
              context.go('/client/dashboard');
              break;
            case 1:
              context.go('/client/workout');
              break;
            case 2:
              context.go('/client/progress');
              break;
            case 3:
              context.go('/client/trainer');
              break;
            case 4:
              context.go('/client/check-in');
              break;
            case 5:
              context.go('/client/explore');
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
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Trainer',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Trainer',
          ),
        ],
      ),
    );
  }
}
