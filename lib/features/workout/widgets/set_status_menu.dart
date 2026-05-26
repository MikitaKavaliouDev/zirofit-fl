import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/providers/rest_timer_manager_provider.dart';

// =============================================================================
// SetStatusBadge
// =============================================================================

/// Colored circle badge showing set number or status indicator letter (W/D/F).
///
/// Tapping opens a popup menu to change the set status between
/// Normal, Warm Up, Drop Set, or Failure.
///
/// Matches iOS `WorkoutSetRow.setNumberView` (lines 91-124).
class SetStatusBadge extends ConsumerWidget {
  /// Current set status.
  final SetStatus status;

  /// Whether the set has been completed.
  final bool isCompleted;

  /// 0-based index of the set within the exercise log.
  final int index;

  /// Called when the user selects a new status from the popup menu.
  final ValueChanged<SetStatus> onStatusChanged;

  const SetStatusBadge({
    super.key,
    required this.status,
    required this.isCompleted,
    required this.index,
    required this.onStatusChanged,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _statusColor() {
    switch (status) {
      case SetStatus.normal:
        return isCompleted ? Colors.green : Colors.grey.shade300;
      case SetStatus.warmUp:
        return Colors.orange;
      case SetStatus.dropSet:
        return Colors.purple;
      case SetStatus.failure:
        return Colors.red;
    }
  }

  String _indicator() {
    switch (status) {
      case SetStatus.normal:
        return '${index + 1}';
      case SetStatus.warmUp:
        return 'W';
      case SetStatus.dropSet:
        return 'D';
      case SetStatus.failure:
        return 'F';
    }
  }

  String _statusLabel(SetStatus s) {
    switch (s) {
      case SetStatus.normal:
        return 'Normal';
      case SetStatus.warmUp:
        return 'Warm Up';
      case SetStatus.dropSet:
        return 'Drop Set';
      case SetStatus.failure:
        return 'Failure';
    }
  }

  Color _menuItemColor(SetStatus s) {
    switch (s) {
      case SetStatus.normal:
        return Colors.grey.shade600;
      case SetStatus.warmUp:
        return Colors.orange;
      case SetStatus.dropSet:
        return Colors.purple;
      case SetStatus.failure:
        return Colors.red;
    }
  }

  String _menuIndicator(SetStatus s) {
    switch (s) {
      case SetStatus.normal:
        return 'N';
      case SetStatus.warmUp:
        return 'W';
      case SetStatus.dropSet:
        return 'D';
      case SetStatus.failure:
        return 'F';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor();
    final indicator = _indicator();
    // Normal + not completed → grey text on light grey bg; otherwise white text
    final isNormalGrey = status == SetStatus.normal && !isCompleted;

    return PopupMenuButton<SetStatus>(
      onSelected: (s) {
        HapticFeedback.lightImpact();
        onStatusChanged(s);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => SetStatus.values.map((s) {
        final selected = s == status;
        return PopupMenuItem<SetStatus>(
          value: s,
          child: Row(
            children: [
              // Colored dot indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _menuItemColor(s),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _menuIndicator(s),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status label
              Text(
                _statusLabel(s),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              ),
              // Checkmark for currently selected status
              if (selected) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 40,
        height: 38,
        alignment: Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              indicator,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isNormalGrey ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// InlineRestTimerRow
// =============================================================================

/// Inline rest timer progress row for a specific workout set.
///
/// Only rendered when [restTimerManagerProvider] indicates a rest timer is
/// actively running and its [RestTimerState.activeSetId] matches [setId].
///
/// Layout: timer icon, monospace bold remaining time, spacer, stop button.
/// Uses orange accent colors.
///
/// Matches iOS `WorkoutSetRow.restTimerView` (lines 326-377).
class InlineRestTimerRow extends ConsumerWidget {
  /// The set ID to match against the rest manager's active set.
  final String setId;

  /// Called when the user taps the stop button.
  final VoidCallback? onStopRest;

  const InlineRestTimerRow({
    super.key,
    required this.setId,
    this.onStopRest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restState = ref.watch(restTimerManagerProvider);

    // Only show when this set has an active rest timer
    final isVisible = restState.isRunning && restState.activeSetId == setId;

    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16),
      child: Row(
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            restState.formattedTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
          ),
          const Spacer(),
          SizedBox(
            height: 24,
            width: 24,
            child: IconButton(
              icon: const Icon(Icons.stop_circle, size: 20),
              color: Colors.orange,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onStopRest,
            ),
          ),
        ],
      ),
    );
  }
}
