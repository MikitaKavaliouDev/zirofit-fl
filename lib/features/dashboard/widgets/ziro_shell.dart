import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/ziro_tab_bar.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_sheet_overlay.dart';
import 'package:zirofit_fl/features/notifications/providers/notifications_provider.dart';

// ---------------------------------------------------------------------------
// Tab helpers
// ---------------------------------------------------------------------------

List<ZiroTab> _trainerTabs(AppMode mode) {
  final isTrainerMode = mode == AppMode.trainer;
  return [
    ZiroTab(
      label: isTrainerMode ? 'Calendar' : 'Calendar',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      route: '/trainer/calendar',
    ),
    ZiroTab(
      label: isTrainerMode ? 'Programs' : 'Programs',
      icon: isTrainerMode ? Icons.fitness_center_outlined : Icons.fitness_center_outlined,
      selectedIcon: isTrainerMode ? Icons.fitness_center : Icons.fitness_center,
      route: '/trainer/programs',
    ),
    const ZiroTab(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/trainer/dashboard',
    ),
    const ZiroTab(
      label: 'Clients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/trainer/clients',
    ),
    const ZiroTab(
      label: 'More',
      icon: Icons.more_horiz_outlined,
      selectedIcon: Icons.more_horiz,
      route: '/trainer/more',
    ),
  ];
}

List<ZiroTab> _clientTabs(AppMode mode) {
  final isTrainerMode = mode == AppMode.trainer;
  return [
    ZiroTab(
      label: isTrainerMode ? 'Explore' : 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      route: '/client/explore',
    ),
    ZiroTab(
      label: isTrainerMode ? 'Workouts' : 'Workouts',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      route: '/client/workout',
    ),
    const ZiroTab(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/client/dashboard',
    ),
    ZiroTab(
      label: isTrainerMode ? 'Progress' : 'Analytics',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      route: '/client/progress',
    ),
    const ZiroTab(
      label: 'More',
      icon: Icons.more_horiz_outlined,
      selectedIcon: Icons.more_horiz,
      route: '/client/more',
    ),
  ];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<ZiroTab> _tabsFor(String location, AppMode mode) {
  final isClient = location.startsWith('/client');
  return isClient ? _clientTabs(mode) : _trainerTabs(mode);
}

// ---------------------------------------------------------------------------
// ZiroShell
// ---------------------------------------------------------------------------

/// Unified shell that replaces both [TrainerShell] and [ClientShell].
///
/// Detects the current role from the route prefix and builds a tab bar
/// whose icons / labels adapt to the current [AppMode].  Includes the
/// same workout‑overlay & mini‑player from the original shells.
class ZiroShell extends ConsumerStatefulWidget {
  final Widget child;

  const ZiroShell({super.key, required this.child});

  @override
  ConsumerState<ZiroShell> createState() => _ZiroShellState();
}

class _ZiroShellState extends ConsumerState<ZiroShell> {
  /// Whether the mode‑selector overlay is shown.
  bool _isModeExpanded = false;

  // ---------------------------------------------------------------------------
  // Tab routing
  // ---------------------------------------------------------------------------

  int _selectedIndex(String location) {
    final isClient = location.startsWith('/client');
    if (isClient) {
      if (location.startsWith('/client/explore')) return 0;
      if (location.startsWith('/client/workout')) return 1;
      if (location.startsWith('/client/dashboard')) return 2;
      if (location.startsWith('/client/progress')) return 3;
      if (location.startsWith('/client/more')) return 4;
      return 2; // default to home
    }
    // Trainer
    if (location.startsWith('/trainer/calendar')) return 0;
    if (location.startsWith('/trainer/programs')) return 1;
    if (location.startsWith('/trainer/dashboard')) return 2;
    if (location.startsWith('/trainer/clients')) return 3;
    if (location.startsWith('/trainer/more')) return 4;
    return 2; // default to home
  }

  void _onTabTap(int index, String location) {
    final mode = ref.read(modeSwitchProvider);
    final tabs = _tabsFor(location, mode);
    if (index < 0 || index >= tabs.length) return;
    final route = tabs[index].route;
    setState(() => _isModeExpanded = false);
    
    // Client workout tab toggles overlay
    if (location.startsWith('/client') && route == '/client/workout') {
      final overlayState = ref.read(sessionOverlayProvider);
      if (overlayState == SessionOverlayState.hidden) {
        ref.read(sessionOverlayProvider.notifier).showFull();
      } else {
        ref.read(sessionOverlayProvider.notifier).toggle();
      }
      return;
    }
    
    context.go(route);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _selectedIndex(location);
    final mode = ref.watch(modeSwitchProvider);
    final tabs = _tabsFor(location, mode);
    final unreadCount = ref.watch(notificationsProvider).unreadCount;
    final overlayState = ref.watch(sessionOverlayProvider);

    // Gap 2: Reset to home tab when mode switches and current tab is invalid
    // for the new mode's tab list (matches iOS behavior: onChange(of: currentMode))
    ref.listen(modeSwitchProvider, (previous, next) {
      if (previous != null && previous != next) {
        final newTabs = _tabsFor(location, next);
        if (index >= newTabs.length) {
          final homeIndex = newTabs.length > 2 ? 2 : newTabs.length - 1;
          context.go(newTabs[homeIndex].route);
        }
      }
    });

    final showMiniPlayer = overlayState == SessionOverlayState.mini;
    final position = ref.watch(workoutOverlayPositionProvider);
    final screenSize = MediaQuery.of(context).size;
    const double miniPlayerWidth = 200;
    const double miniPlayerHeight = 72;

    return Scaffold(
      body: Stack(
        children: [
          widget.child,

          // Full workout bottom sheet
          if (overlayState == SessionOverlayState.full)
            WorkoutSheetOverlay(
              onFinishWorkout: () {
                // let overlay self-manage
              },
              onCancelWorkout: () {
                // let overlay self-manage
              },
            ),

          // Floating mini player
          if (showMiniPlayer)
            Positioned(
              left: position.dx,
              top: position.dy,
              width: miniPlayerWidth,
              child: GestureDetector(
                onPanUpdate: (details) {
                  ref.read(workoutOverlayPositionProvider.notifier).state =
                      Offset(
                    (position.dx + details.delta.dx).clamp(
                      0,
                      screenSize.width - miniPlayerWidth,
                    ),
                    (position.dy + details.delta.dy).clamp(
                      0,
                      screenSize.height - miniPlayerHeight,
                    ),
                  );
                },
                child: WorkoutMiniPlayer(
                  onExpand: () =>
                      ref.read(sessionOverlayProvider.notifier).showFull(),
                  onClose: () =>
                      ref.read(sessionOverlayProvider.notifier).hide(),
                ),
              ),
            ),
        ],
      ),
      // Gap 1: Hide tab bar when full-screen workout overlay is active
      // (matches iOS behavior: tab bar hidden during active session)
      bottomNavigationBar: overlayState == SessionOverlayState.full
          ? null
          : ZiroTabBar(
              selectedIndex: index,
              onTap: (i) => _onTabTap(i, location),
              tabs: tabs,
              isModeExpanded: _isModeExpanded,
              onToggleModeExpanded: () =>
                  setState(() => _isModeExpanded = !_isModeExpanded),
              currentMode: mode,
              onModeChanged: (newMode) {
                ref.read(modeSwitchProvider.notifier).setMode(newMode);
                setState(() => _isModeExpanded = false);
              },
              onDoubleTapTab: () {
                final route = tabs[index].route;
                // Skip route navigation for overlay-based tabs (client Workout)
                if (location.startsWith('/client') && route == '/client/workout') {
                  return;
                }
                context.go(route);
              },
              homeBadgeCount: unreadCount,
            ),
    );
  }
}
