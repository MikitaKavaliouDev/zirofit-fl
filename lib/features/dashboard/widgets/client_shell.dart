import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientShell extends StatelessWidget {
  final Widget child;

  const ClientShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/client/dashboard')) return 0;
    if (location.startsWith('/client/workout')) return 1;
    if (location.startsWith('/client/progress')) return 2;
    if (location.startsWith('/client/trainer')) return 3;
    if (location.startsWith('/client/check-in')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
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
        ],
      ),
    );
  }
}
