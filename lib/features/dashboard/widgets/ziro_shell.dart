import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/providers/mode_switch_provider.dart';
import 'package:zirofit_fl/features/auth/widgets/role_login_sheet.dart';
import 'package:zirofit_fl/features/dashboard/widgets/ziro_tab_bar.dart';
import 'package:zirofit_fl/features/workout/providers/session_overlay_provider.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_mini_player.dart';
import 'package:zirofit_fl/features/workout/widgets/workout_sheet_overlay.dart';
import 'package:zirofit_fl/core/services/notification_routing.dart';
import 'package:zirofit_fl/features/notifications/providers/cross_mode_alert_provider.dart';
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
    
    // Pop to root when re-tapping the already active tab
    if (index == _selectedIndex(location)) {
      final router = GoRouter.of(context);
      while (router.canPop()) {
        router.pop();
      }
    }

    context.go(route);
  }

  // ---------------------------------------------------------------------------
  // Cross-mode notification alert
  // ---------------------------------------------------------------------------

  /// Shows an AlertDialog asking the user whether to switch to the
  /// role required by the push notification.
  ///
  /// On confirm:
  /// 1. Switches auth session to the target role
  /// 2. Sets the display mode to match
  /// 3. Dismisses the alert
  /// 4. Navigates to the notification's intended screen
  Future<void> _showCrossModeAlert(CrossModeAlertState alert) async {
    final targetLabel = AuthNotifier.roleLabel(alert.targetRole);

    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cross-Mode Notification'),
        content: Text(
          'This notification requires $targetLabel mode. Switch now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldSwitch == true) {
      // 1. Switch the auth session to the target role
      await ref.read(authProvider.notifier).switchToRole(alert.targetRole);

      // 2. Set the display mode to match
      final targetMode = alert.targetRole == 'trainer'
          ? AppMode.trainer
          : AppMode.personal;
      await ref.read(modeSwitchProvider.notifier).setMode(targetMode);

      // 3. Dismiss the alert
      ref.read(crossModeAlertProvider.notifier).dismiss();

      // 4. Navigate to the notification's intended screen
      if (alert.data.isNotEmpty && mounted) {
        final router = GoRouter.of(context);
        NotificationRoutingService.handleNotificationTap(
          alert.data,
          router,
        );
      }
    } else {
      // User cancelled — just dismiss the alert
      ref.read(crossModeAlertProvider.notifier).dismiss();
    }
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

    // Cross-mode notification alert: when a push notification targets a
    // different role than the user's current mode, show a dialog offering
    // to switch modes.
    ref.listen<CrossModeAlertState?>(crossModeAlertProvider, (previous, next) {
      if (!mounted) return;
      if (next != null &&
          next.isAlertActive &&
          (previous == null || !previous.isAlertActive)) {
        _showCrossModeAlert(next);
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
              onModeChanged: (newMode) async {
                final authState = ref.read(authProvider);
                final targetRole =
                    newMode == AppMode.trainer ? 'trainer' : 'client';

                // Gate: if the user's role doesn't match the target mode,
                // show a login sheet before switching.
                if (authState.role != targetRole) {
                  final loggedIn = await RoleLoginSheet.show(
                    context,
                    targetRole: targetRole,
                  );
                  if (!loggedIn || !context.mounted) {
                    setState(() => _isModeExpanded = false);
                    return;
                  }
                }

                ref.read(modeSwitchProvider.notifier).setMode(newMode);
                setState(() => _isModeExpanded = false);
              },
              onDoubleTapTab: () {
                final route = tabs[index].route;
                // Skip route navigation for overlay-based tabs (client Workout)
                if (location.startsWith('/client') && route == '/client/workout') {
                  return;
                }
                // Pop to root on double-tap of active tab
                final router = GoRouter.of(context);
                while (router.canPop()) {
                  router.pop();
                }
                context.go(route);
              },
              homeBadgeCount: unreadCount,
            ),
    );
  }
}
