import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_sheet_overlay.dart';

class ClientShell extends ConsumerWidget {
  final Widget child;

  const ClientShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith('/client/dashboard')) return 0;
    if (location.startsWith('/client/workout')) return 1;
    if (location.startsWith('/client/progress')) return 2;
    if (location.startsWith('/client/check-in')) return 3;
    if (location.startsWith('/client/explore')) return 4;
    if (location.startsWith('/client/settings')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);
    final overlayState = ref.watch(sessionOverlayProvider);

    final position = ref.watch(workoutOverlayPositionProvider);
    final screenSize = MediaQuery.of(context).size;
    const double miniPlayerWidth = 200;
    const double miniPlayerHeight = 72;

    return Scaffold(
      body: Stack(
        children: [
          child,

          // Workout sheet overlay (full workout bottom sheet)
          // Always mounted so AnimatedPositioned can animate transitions.
          WorkoutSheetOverlay(
              onFinishWorkout: () {
                // After finish, just let the overlay hide itself
              },
              onCancelWorkout: () {
                // After cancel, just let the overlay hide itself
              },
            ),

          // Floating mini player (when minimized)
          if (overlayState == SessionOverlayState.mini)
            Positioned(
              left: position.dx,
              top: position.dy,
              width: miniPlayerWidth,
              child: GestureDetector(
                onPanUpdate: (details) {
                  ref.read(workoutOverlayPositionProvider.notifier).state = Offset(
                    (position.dx + details.delta.dx).clamp(0, screenSize.width - miniPlayerWidth),
                    (position.dy + details.delta.dy).clamp(0, screenSize.height - miniPlayerHeight),
                  );
                },
                child: WorkoutMiniPlayer(
                  onExpand: () => ref.read(sessionOverlayProvider.notifier).showFull(),
                  onClose: () => ref.read(sessionOverlayProvider.notifier).hide(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 6) {
            // Mode switch - stay on client mode
            ref.read(modeSwitchProvider.notifier).switchMode();
            return;
          }
          switch (i) {
            case 0:
              context.go('/client/dashboard');
              break;
            case 1:
              // Workout tab: toggle overlay state
              final tabOverlayState = ref.read(sessionOverlayProvider);
              if (tabOverlayState == SessionOverlayState.hidden) {
                ref.read(sessionOverlayProvider.notifier).showFull();
              } else {
                ref.read(sessionOverlayProvider.notifier).toggle();
              }
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
            case 5:
              context.go('/client/settings');
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
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