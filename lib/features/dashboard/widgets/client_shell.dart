import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';

class ClientShell extends ConsumerWidget {
  final Widget child;

  const ClientShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/client/dashboard')) return 0;
    if (location.startsWith('/client/workout')) return 1;
    if (location.startsWith('/client/progress')) return 2;
    if (location.startsWith('/client/check-in')) return 3;
    if (location.startsWith('/client/explore')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);
    final overlayState = ref.watch(sessionOverlayProvider);

    // Mini player visible when session is mini state
    final showMiniPlayer = overlayState == SessionOverlayState.mini;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Mini player above tab bar when in mini state
          if (showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80, // above nav bar
              child: WorkoutMiniPlayer(
                onExpand: () {
                  ref.read(sessionOverlayProvider.notifier).state = SessionOverlayState.full;
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: showMiniPlayer
          ? null // Hide nav bar when mini player is shown (matches iOS)
          : NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 5) {
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
              context.go('/client/check-in');
              break;
            case 4:
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