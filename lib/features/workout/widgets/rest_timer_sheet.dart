import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/features/workout/providers/rest_timer_manager_provider.dart';

// =============================================================================
// RestTimerSheet
// =============================================================================

/// A modal sheet for managing rest timer, matching iOS [RestTimerSheet] layout.
///
/// - **Active timer**: circular progress (orange), remaining time, +/-10s
///   adjustment capsules, and a "Skip Rest" button.
/// - **Selection view**: 3-column quick-preset grid (30s–5min) and a custom
///   duration section with minutes/seconds wheel pickers + "Start Timer" button.
/// - A "Rest Finished!" toast appears when the countdown reaches zero.
class RestTimerSheet extends ConsumerStatefulWidget {
  const RestTimerSheet({super.key});

  /// Presents the sheet as a full-screen slide-up overlay.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Rest Timer',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const RestTimerSheet(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          )),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends ConsumerState<RestTimerSheet> {
  // ---------------------------------------------------------------------------
  // Local state
  // ---------------------------------------------------------------------------

  int _selectedMinutes = 2;
  int _selectedSeconds = 0;
  bool _showToast = false;
  // Removed: using ref.listen() instead of manual StreamSubscription.

  /// Quick-preset values in seconds (matching iOS: 30, 60, 90, 120, 180, 300).
  static const List<int> _presets = [30, 60, 90, 120, 180, 300];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Seed the custom picker from the last-used total time.
    final state = ref.read(restTimerManagerProvider);
    if (state.totalTime > 0) {
      _selectedMinutes = state.totalTime ~/ 60;
      _selectedSeconds = state.totalTime % 60;
    }

    // Listen for rest-finished events to show the toast (iOS parity).
    ref.listen(restTimerFinishedProvider, (_, next) {
      if (next.valueOrNull == null) return;
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _showToast = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showToast = false);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Formats a duration in seconds to "m:ss" (e.g. 90 → "1:30").
  String _formatPreset(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  void _onStartTimer() {
    final total = (_selectedMinutes * 60) + _selectedSeconds;
    if (total <= 0) return;
    HapticFeedback.lightImpact();
    ref.read(restTimerManagerProvider.notifier).start(duration: total);
    Navigator.of(context).pop();
  }

  void _onPresetTap(int seconds) {
    HapticFeedback.lightImpact();
    ref.read(restTimerManagerProvider.notifier).start(duration: seconds);
    Navigator.of(context).pop();
  }

  void _onSkipRest() {
    HapticFeedback.lightImpact();
    ref.read(restTimerManagerProvider.notifier).stop();
    Navigator.of(context).pop();
  }

  void _onAdjust(int delta) {
    HapticFeedback.lightImpact();
    ref.read(restTimerManagerProvider.notifier).addTime(delta);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = context.themeColors;
    final restState = ref.watch(restTimerManagerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glass-morphism backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Sheet container (pinned to bottom with top rounded corners)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: tc.backgroundSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // ----- Drag handle -----
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: tc.backgroundTertiary,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // ----- Header -----
                    _HeaderBar(onDismiss: _dismiss, tc: tc, theme: theme),

                    // ----- Body -----
                    if (restState.isRunning)
                      Expanded(
                        child: _ActiveTimerBody(
                          state: restState,
                          theme: theme,
                          tc: tc,
                          onSkipRest: _onSkipRest,
                          onAdjust: _onAdjust,
                        ),
                      )
                    else
                      Expanded(
                        child: _SelectionBody(
                          theme: theme,
                          tc: tc,
                          selectedMinutes: _selectedMinutes,
                          selectedSeconds: _selectedSeconds,
                          presets: _presets,
                          formatPreset: _formatPreset,
                          onPresetTap: _onPresetTap,
                          onMinutesChanged: (v) =>
                              setState(() => _selectedMinutes = v),
                          onSecondsChanged: (v) =>
                              setState(() => _selectedSeconds = v),
                          onStartTimer: _onStartTimer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ----- "Rest Finished!" toast overlay -----
          if (_showToast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 40,
              right: 40,
              child: TickerMode(
                enabled: _showToast,
                child: _RestFinishedToast(theme: theme),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

/// Title bar with dismiss circle on the left and centered "Rest Timer" label.
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onDismiss,
    required this.tc,
    required this.theme,
  });

  final VoidCallback onDismiss;
  final ThemeColors tc;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Dismiss (X) button
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tc.backgroundTertiary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.grey),
            ),
          ),

          const Spacer(),

          // Title
          Text(
            'Rest Timer',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tc.textPrimary,
            ),
          ),

          const Spacer(),

          // Balance the dismiss button width
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

// =============================================================================
// Active Timer Body
// =============================================================================

/// Shown when [RestTimerState.isRunning] is true.
///
/// Displays a circular progress ring, remaining time, "Resting" label,
/// +/-10s capsules, and a "Skip Rest" button.
class _ActiveTimerBody extends StatelessWidget {
  const _ActiveTimerBody({
    required this.state,
    required this.theme,
    required this.tc,
    required this.onSkipRest,
    required this.onAdjust,
  });

  final RestTimerState state;
  final ThemeData theme;
  final ThemeColors tc;
  final VoidCallback onSkipRest;
  final void Function(int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),

        // ---- Circular progress + time display ----
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: tc.backgroundTertiary,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.transparent),
              ),
              // Orange progress ring
              CircularProgressIndicator(
                value: state.progress,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              // Time + label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.formattedTime,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: tc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Resting',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // ---- +/-10s adjustment capsules ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustCapsule(
              label: '-10s',
              onTap: () => onAdjust(-10),
              tc: tc,
            ),
            const SizedBox(width: 20),
            _AdjustCapsule(
              label: '+10s',
              onTap: () => onAdjust(10),
              tc: tc,
            ),
          ],
        ),

        const Spacer(),

        // ---- Skip Rest button ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSkipRest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Skip Rest',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// =============================================================================
// Selection Body (Quick Select + Custom Duration + Start Timer)
// =============================================================================

/// Shown when the rest timer is idle.
///
/// Contains a 3-column quick-preset grid, a custom duration picker section
/// with minutes (0–15) and seconds (0–55 step 5) wheel pickers, and a
/// fixed "Start Timer" button at the bottom.
class _SelectionBody extends StatelessWidget {
  const _SelectionBody({
    required this.theme,
    required this.tc,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.presets,
    required this.formatPreset,
    required this.onPresetTap,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    required this.onStartTimer,
  });

  final ThemeData theme;
  final ThemeColors tc;
  final int selectedMinutes;
  final int selectedSeconds;
  final List<int> presets;
  final String Function(int) formatPreset;
  final void Function(int) onPresetTap;
  final void Function(int) onMinutesChanged;
  final void Function(int) onSecondsChanged;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _QuickSelectSection(
                  presets: presets,
                  formatPreset: formatPreset,
                  onTap: onPresetTap,
                ),
                const SizedBox(height: 24),
                _CustomDurationSection(
                  theme: theme,
                  tc: tc,
                  selectedMinutes: selectedMinutes,
                  selectedSeconds: selectedSeconds,
                  onMinutesChanged: onMinutesChanged,
                  onSecondsChanged: onSecondsChanged,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Start Timer button (pinned to bottom)
        _StartTimerButton(onPressed: onStartTimer),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Select Grid
// ---------------------------------------------------------------------------

/// A 3-column grid of preset timer options (0:30, 1:00, 1:30, 2:00, 3:00, 5:00).
class _QuickSelectSection extends StatelessWidget {
  const _QuickSelectSection({
    required this.presets,
    required this.formatPreset,
    required this.onTap,
  });

  final List<int> presets;
  final String Function(int) formatPreset;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'QUICK SELECT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: presets.map((seconds) {
              return GestureDetector(
                onTap: () => onTap(seconds),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    formatPreset(seconds),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // textPrimary (light mode)
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Duration Pickers
// ---------------------------------------------------------------------------

/// Side-by-side wheel pickers for minutes (0–15) and seconds (0–55, step 5).
class _CustomDurationSection extends StatelessWidget {
  const _CustomDurationSection({
    required this.theme,
    required this.tc,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
  });

  final ThemeData theme;
  final ThemeColors tc;
  final int selectedMinutes;
  final int selectedSeconds;
  final void Function(int) onMinutesChanged;
  final void Function(int) onSecondsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'CUSTOM DURATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tc.backgroundTertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Column headers
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Seconds',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Wheel pickers
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    // Minutes picker (0–15)
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMinutes,
                        ),
                        onSelectedItemChanged: (index) {
                          onMinutesChanged(index);
                          HapticFeedback.selectionClick();
                        },
                        children: List.generate(16, (i) {
                          return Center(
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: tc.textPrimary,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Seconds picker (0–55, step 5)
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedSeconds ~/ 5,
                        ),
                        onSelectedItemChanged: (index) {
                          onSecondsChanged(index * 5);
                          HapticFeedback.selectionClick();
                        },
                        children: List.generate(12, (i) {
                          final value = i * 5;
                          return Center(
                            child: Text(
                              value.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: tc.textPrimary,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Start Timer Button
// ---------------------------------------------------------------------------

/// Full-width blue button with a play icon and subtle shadow.
class _StartTimerButton extends StatelessWidget {
  const _StartTimerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
      decoration: BoxDecoration(
        color: context.themeColors.backgroundSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
        label: const Text(
          'Start Timer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// =============================================================================
// Rest Finished Toast
// =============================================================================

/// An overlay toast that appears when the rest timer finishes.
///
/// Mirrors the iOS toast: green checkmark + "Rest Finished!" text
/// on a dark pill background.
class _RestFinishedToast extends StatelessWidget {
  const _RestFinishedToast({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              'Rest Finished!',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Adjustment Capsule
// =============================================================================

/// Pill-shaped button for adjusting the timer by ±10 seconds.
class _AdjustCapsule extends StatelessWidget {
  const _AdjustCapsule({
    required this.label,
    required this.onTap,
    required this.tc,
  });

  final String label;
  final VoidCallback onTap;
  final ThemeColors tc;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: tc.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
