import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_sheet_overlay.dart';

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
    final overlayState = ref.watch(sessionOverlayProvider);

    final showMiniPlayer = overlayState == SessionOverlayState.mini;

    final screenSize = MediaQuery.of(context).size;
    const miniPlayerWidth = 200.0;
    const miniPlayerHeight = 60.0;
    final position = ref.watch(workoutOverlayPositionProvider);

    return Scaffold(
      body: Stack(
        children: [
          child,

          // Workout sheet overlay (full workout bottom sheet)
          // Always mounted so AnimatedPositioned can animate transitions.
          WorkoutSheetOverlay(
              onFinishWorkout: () { /* let overlay self-manage */ },
              onCancelWorkout: () { /* let overlay self-manage */ },
            ),

          // Floating mini player (when minimized)
          if (showMiniPlayer)
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
        ],
      ),
    );
  }
}