import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

// ---------------------------------------------------------------------------
// RestTimerSheet
// ---------------------------------------------------------------------------

/// A modal bottom sheet that provides a full rest timer experience.
///
/// Features:
/// - Circular countdown timer display (mm:ss) with animated progress ring
/// - Preset buttons: 30s, 60s, 90s, 120s, 180s (current selection highlighted)
/// - Custom time picker with minutes/seconds dropdowns
/// - Pause / Resume, +30s, −30s, and Skip buttons
///
/// State is driven by [workoutEnhancementProvider].
class RestTimerSheet extends ConsumerStatefulWidget {
  const RestTimerSheet({super.key});

  /// Shows this sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RestTimerSheet(),
    );
  }

  @override
  ConsumerState<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends ConsumerState<RestTimerSheet>
    with SingleTickerProviderStateMixin {
  // -- Internal timer for countdown --
  Timer? _countdownTimer;
  int _remainingSeconds = 90;
  bool _isRunning = false;
  int _totalSeconds = 90;

  // -- Animation controller for the circular progress --
  late final AnimationController _animController;
  late Animation<double> _progressAnimation;

  // -- Custom time picker state --
  int _customMinutes = 0;
  int _customSeconds = 0;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(workoutEnhancementProvider).restTimerSettings;
    _remainingSeconds = settings.defaultSeconds;
    _totalSeconds = settings.defaultSeconds;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Timer control
  // ---------------------------------------------------------------------------

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    setState(() => _isRunning = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _stopTimer();
        return;
      }
      setState(() => _remainingSeconds--);
      _syncProgress();
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() => _isRunning = false);
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() => _isRunning = false);
    _syncProgress();
  }

  void _resetTimer(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _totalSeconds = seconds;
      _isRunning = false;
      _customMinutes = seconds ~/ 60;
      _customSeconds = seconds % 60;
    });
    _syncProgress();
    ref.read(workoutEnhancementProvider.notifier).selectPreset(seconds);
  }

  void _addTime(int delta) {
    setState(() {
      _remainingSeconds = (_remainingSeconds + delta).clamp(0, 600);
      _totalSeconds = _totalSeconds.clamp(0, 600);
    });
    _syncProgress();
  }

  void _skip() {
    setState(() {
      _remainingSeconds = 0;
      _isRunning = false;
    });
    _syncProgress();
    Navigator.of(context).pop();
  }

  void _syncProgress() {
    final progress =
        _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: progress,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _animController
      ..reset()
      ..forward();
  }

  void _applyCustomTime() {
    final total = _customMinutes * 60 + _customSeconds;
    if (total > 0) {
      ref
          .read(workoutEnhancementProvider.notifier)
          .setCustomTime(_customMinutes, _customSeconds);
      _resetTimer(total);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(workoutEnhancementProvider);
    final settings = state.restTimerSettings;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Title
            Text(
              'Rest Timer',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ── Circular countdown ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _CircularRestTimer(
                remainingSeconds: _remainingSeconds,
                totalSeconds: _totalSeconds,
                progress: _progressAnimation,
                isRunning: _isRunning,
                theme: theme,
              ),
            ),

            const SizedBox(height: 8),

            // ── Preset buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: settings.presets.map((seconds) {
                  final isSelected = seconds == _remainingSeconds;
                  return ChoiceChip(
                    label: Text(_formatPreset(seconds)),
                    selected: isSelected,
                    onSelected: (_) => _resetTimer(seconds),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Custom time picker ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minutes
                  _TimePickerButton(
                    label: 'Min',
                    value: _customMinutes,
                    onIncrement: () => setState(() {
                      _customMinutes = (_customMinutes + 1).clamp(0, 10);
                    }),
                    onDecrement: () => setState(() {
                      _customMinutes = (_customMinutes - 1).clamp(0, 10);
                    }),
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  // Seconds
                  _TimePickerButton(
                    label: 'Sec',
                    value: _customSeconds,
                    displayValue: _customSeconds.toString().padLeft(2, '0'),
                    onIncrement: () => setState(() {
                      _customSeconds = (_customSeconds + 1).clamp(0, 59);
                    }),
                    onDecrement: () => setState(() {
                      _customSeconds = (_customSeconds - 1).clamp(0, 59);
                    }),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _applyCustomTime,
                    child: const Text('Set'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // −30s
                  _ActionButton(
                    icon: Icons.remove_circle_outline,
                    label: '-30s',
                    onTap: () => _addTime(-30),
                    theme: theme,
                  ),
                  const SizedBox(width: 12),

                  // Pause / Resume
                  _ActionButton(
                    icon: _isRunning ? Icons.pause_circle : Icons.play_circle,
                    label: _isRunning ? 'Pause' : 'Start',
                    isPrimary: true,
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    theme: theme,
                  ),
                  const SizedBox(width: 12),

                  // +30s
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: '+30s',
                    onTap: () => _addTime(30),
                    theme: theme,
                  ),
                  const SizedBox(width: 12),

                  // Skip
                  _ActionButton(
                    icon: Icons.skip_next,
                    label: 'Skip',
                    onTap: _skip,
                    theme: theme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatPreset(int seconds) {
    if (seconds >= 60) {
      final min = seconds ~/ 60;
      final sec = seconds % 60;
      return sec > 0 ? '${min}m ${sec}s' : '${min}m';
    }
    return '${seconds}s';
  }
}

// ---------------------------------------------------------------------------
// Circular Rest Timer
// ---------------------------------------------------------------------------

class _CircularRestTimer extends AnimatedWidget {
  const _CircularRestTimer({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.progress,
    required this.isRunning,
    required this.theme,
  }) : super(listenable: progress);

  final int remainingSeconds;
  final int totalSeconds;
  final Animation<double> progress;
  final bool isRunning;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.value;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    const size = 180.0;
    const strokeWidth = 10.0;
    final color = progressValue > 0.5
        ? theme.colorScheme.primary
        : progressValue > 0.25
            ? Colors.orange
            : theme.colorScheme.error;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation(theme.colorScheme.surfaceContainerHighest),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRunning ? 'RESTING' : 'PAUSED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Button (compact icon + label)
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isPrimary
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPrimary
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time Picker Button (increment / decrement)
// ---------------------------------------------------------------------------

/// A compact control with up/down arrows and a displayed value.
class _TimePickerButton extends StatelessWidget {
  final String label;
  final int value;
  final String? displayValue;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ThemeData theme;

  const _TimePickerButton({
    required this.label,
    required this.value,
    this.displayValue,
    required this.onIncrement,
    required this.onDecrement,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Increment
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 20),
            onPressed: onIncrement,
          ),
          // Value
          Text(
            displayValue ?? value.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // Decrement
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 20),
            onPressed: onDecrement,
          ),
          // Label
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
