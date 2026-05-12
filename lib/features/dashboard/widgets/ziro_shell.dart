import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/dashboard/widgets/ziro_tab_bar.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_sheet_overlay.dart';

// ---------------------------------------------------------------------------
// Tab helpers
// ---------------------------------------------------------------------------

// Personal‑mode icon mapping (mirrors iOS CustomTabBar.swift):
//   programs / Explore → Icons.auto_awesome  (sparkles)
//   clients  / Workouts → Icons.schedule      (clock)
//   home     / Home     → Icons.home          (house.fill – default)
//   analytics           → Icons.analytics     (chart.xyaxis.line)
//   more     / More     → Icons.more_horiz    (ellipsis.circle – default)

/// Trainer‑mode tabs for the trainer shell.
List<ZiroTab> _trainerTrainerTabs() => const [
      ZiroTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/trainer/dashboard',
      ),
      ZiroTab(
        label: 'Clients',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        route: '/trainer/clients',
      ),
      ZiroTab(
        label: 'Check-Ins',
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist,
        route: '/trainer/check-ins',
      ),
      ZiroTab(
        label: 'Calendar',
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        route: '/trainer/calendar',
      ),
      ZiroTab(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        route: '/trainer/profile',
      ),
      ZiroTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        route: '/trainer/settings',
      ),
    ];

/// Personal‑mode tabs for the trainer shell (tab rebinding).
List<ZiroTab> _trainerPersonalTabs() => const [
      ZiroTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/trainer/dashboard',
      ),
      ZiroTab(
        label: 'Workouts',
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        route: '/trainer/clients',
      ),
      ZiroTab(
        label: 'Progress',
        icon: Icons.trending_up_outlined,
        selectedIcon: Icons.trending_up,
        route: '/trainer/check-ins',
      ),
      ZiroTab(
        label: 'Calendar',
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        route: '/trainer/calendar',
      ),
      ZiroTab(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        route: '/trainer/profile',
      ),
      ZiroTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        route: '/trainer/settings',
      ),
    ];

/// Trainer‑mode tabs for the client shell.
List<ZiroTab> _clientTrainerTabs() => const [
      ZiroTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/client/dashboard',
      ),
      ZiroTab(
        label: 'Workout',
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        route: '/client/workout',
      ),
      ZiroTab(
        label: 'Progress',
        icon: Icons.trending_up_outlined,
        selectedIcon: Icons.trending_up,
        route: '/client/progress',
      ),
      ZiroTab(
        label: 'Check-in',
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
        route: '/client/check-in',
      ),
      ZiroTab(
        label: 'Explore',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        route: '/client/explore',
      ),
      ZiroTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        route: '/client/settings',
      ),
    ];

/// Personal‑mode tabs for the client shell (tab rebinding).
List<ZiroTab> _clientPersonalTabs() => const [
      ZiroTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/client/dashboard',
      ),
      ZiroTab(
        label: 'Workout',
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        route: '/client/workout',
      ),
      ZiroTab(
        label: 'Progress',
        icon: Icons.trending_up_outlined,
        selectedIcon: Icons.trending_up,
        route: '/client/progress',
      ),
      ZiroTab(
        label: 'Check-in',
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
        route: '/client/check-in',
      ),
      ZiroTab(
        label: 'Explore',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        route: '/client/explore',
      ),
      ZiroTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        route: '/client/settings',
      ),
    ];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Detect whether location resembles a client route.
bool _isClientShell(String location) => location.startsWith('/client');

/// Determine the correct tab list based on prefix and current [mode].
List<ZiroTab> _tabsFor(String location, AppMode mode) {
  final isClient = _isClientShell(location);
  if (isClient) {
    return mode == AppMode.trainer
        ? _clientTrainerTabs()
        : _clientPersonalTabs();
  }
  // Default: trainer shell
  return mode == AppMode.trainer
      ? _trainerTrainerTabs()
      : _trainerPersonalTabs();
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
    final isClient = _isClientShell(location);

    if (isClient) {
      if (location.startsWith('/client/dashboard')) return 0;
      if (location.startsWith('/client/workout')) return 1;
      if (location.startsWith('/client/progress')) return 2;
      if (location.startsWith('/client/check-in')) return 3;
      if (location.startsWith('/client/explore')) return 4;
      if (location.startsWith('/client/settings')) return 5;
      return 0;
    }

    // Trainer shell
    if (location.startsWith('/trainer/dashboard')) return 0;
    if (location.startsWith('/trainer/clients')) return 1;
    if (location.startsWith('/trainer/check-ins')) return 2;
    if (location.startsWith('/trainer/calendar')) return 3;
    if (location.startsWith('/trainer/profile')) return 4;
    if (location.startsWith('/trainer/settings')) return 5;
    return 0;
  }

  void _onTabTap(int index, String location) {
    final mode = ref.read(modeSwitchProvider);
    final tabs = _tabsFor(location, mode);

    if (index < 0 || index >= tabs.length) return;
    final route = tabs[index].route;

    // Collapse mode selector when navigating
    setState(() => _isModeExpanded = false);

    // Special handling: client workout tab toggles overlay
    if (_isClientShell(location) && route == '/client/workout') {
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
    final overlayState = ref.watch(sessionOverlayProvider);

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
      bottomNavigationBar: ZiroTabBar(
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
      ),
    );
  }
}
