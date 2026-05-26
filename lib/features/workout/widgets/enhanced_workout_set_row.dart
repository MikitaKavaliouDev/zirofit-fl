import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/workout_set.dart';
import 'package:zirofit_fl/features/workout/models/workout_focus_state.dart';

/// Enhanced WorkoutSetRow matching iOS WorkoutSetRow.swift
///
/// Features:
/// - Focus-aware input fields with blinking cursor
/// - Set status menu (normal, warmup, dropset, failure)
/// - Previous workout data display below inputs
/// - Inline rest timer support
/// - Swipe-to-delete with confirmation
/// - Completion toggle with haptic feedback
class EnhancedWorkoutSetRow extends ConsumerStatefulWidget {
  final WorkoutSet set;
  final int index;
  final WorkoutSet? previousSet;
  final bool isActive;
  final String activeText;
  final bool isInputSelected;
  final SessionFocusField? focusedField;
  final void Function(SessionFocusField field) onFocus;
  final void Function(double? weight) onWeightChanged;
  final void Function(int? reps) onRepsChanged;
  final void Function(double? rpe) onRpeChanged;
  final void Function(SetStatus status) onStatusChanged;
  final void Function() onDelete;
  final void Function() onComplete;
  final void Function()? onStartRest;
  final void Function()? onStopRest;
  final int? activeRestSeconds;
  final String? activeSetId;
  final bool restManagerRunning;

  const EnhancedWorkoutSetRow({
    super.key,
    required this.set,
    required this.index,
    this.previousSet,
    this.isActive = false,
    this.activeText = '',
    this.isInputSelected = false,
    this.focusedField,
    required this.onFocus,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRpeChanged,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onComplete,
    this.onStartRest,
    this.onStopRest,
    this.activeRestSeconds,
    this.activeSetId,
    this.restManagerRunning = false,
  });

  @override
  ConsumerState<EnhancedWorkoutSetRow> createState() => _EnhancedWorkoutSetRowState();
}

class _EnhancedWorkoutSetRowState extends ConsumerState<EnhancedWorkoutSetRow>
    with SingleTickerProviderStateMixin {
  bool _showError = false;
  double _dragOffset = 0.0;
  bool _isSwiping = false;
  late AnimationController _swipeController;

  static const double _swipeThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Listen to focused field changes to handle errors
    if (widget.isActive && widget.activeSetId == widget.set.id) {
      _scrollToFocus();
    }
  }

  @override
  void didUpdateWidget(EnhancedWorkoutSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameActive = widget.isActive && widget.activeSetId == widget.set.id;
    final wasActive = oldWidget.isActive && oldWidget.activeSetId == widget.set.id;
    if (becameActive && !wasActive) {
      _scrollToFocus();
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _scrollToFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _clearError() {
    if (_showError) {
      setState(() => _showError = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Swipe-to-complete gesture handlers
  // ---------------------------------------------------------------------------

  void _onHorizontalDragStart(DragStartDetails details) {
    if (widget.set.isCompleted) return;
    setState(() {
      _dragOffset = 0;
      _isSwiping = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.set.isCompleted || !_isSwiping) return;
    final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, 200.0);
    if (newOffset != _dragOffset) {
      setState(() {
        _dragOffset = newOffset;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.set.isCompleted || !_isSwiping) return;
    _isSwiping = false;

    if (_dragOffset >= _swipeThreshold) {
      HapticFeedback.mediumImpact();
      // Reset offset immediately to avoid visual glitch when provider rebuilds
      _dragOffset = 0;
      widget.onComplete();
    } else {
      _animateSwipeBack();
    }
  }

  void _animateSwipeBack() {
    final start = _dragOffset;
    if (start <= 0) {
      setState(() => _dragOffset = 0);
      return;
    }

    final animation = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(
        parent: _swipeController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    void listener() {
      setState(() {
        _dragOffset = animation.value;
      });
    }

    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        animation.removeListener(listener);
        _swipeController.removeStatusListener(statusListener);
        setState(() => _dragOffset = 0);
      }
    }

    animation.addListener(listener);
    _swipeController.addStatusListener(statusListener);
    _swipeController.forward(from: 0.0);
  }

  Color _getStatusColor(SetStatus status) {
    switch (status) {
      case SetStatus.normal:
        return widget.set.isCompleted
            ? Colors.green
            : Colors.grey.shade300;
      case SetStatus.warmUp:
        return Colors.orange;
      case SetStatus.dropSet:
        return Colors.purple;
      case SetStatus.failure:
        return Colors.red;
    }
  }

  String _getStatusIndicator(SetStatus status) {
    switch (status) {
      case SetStatus.normal:
        return '${widget.index + 1}';
      case SetStatus.warmUp:
        return 'W';
      case SetStatus.dropSet:
        return 'D';
      case SetStatus.failure:
        return 'F';
    }
  }

  /// Builds the green-tinted background revealed during rightward swipe.
  Widget _buildSwipeBackground() {
    final opacity = (_dragOffset / _swipeThreshold).clamp(0.0, 1.0);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: opacity * 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Opacity(
              opacity: opacity,
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.set.status);

    final rowContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main row with set details
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              // Set number / status badge
              _buildStatusBadge(theme, statusColor),
              const SizedBox(width: 8),

              // Weight input
              Expanded(child: _buildWeightInput(theme)),
              const SizedBox(width: 8),

              // Reps input
              Expanded(child: _buildRepsInput(theme)),
              const SizedBox(width: 8),

              // Tempo input
              _buildTempoInput(theme),
              const SizedBox(width: 8),

              // RPE button
              _buildRpeButton(theme),
              const SizedBox(width: 8),

              // Completion toggle
              _buildCompletionToggle(theme),
            ],
          ),
        ),

        // Rest timer row (when active for this set)
        if (widget.activeSetId == widget.set.id && widget.restManagerRunning) ...[
          const SizedBox(height: 4),
          _buildRestTimerRow(theme),
        ],

        // Previous set data
        if (_hasPreviousData)
          _buildPreviousDataRow(theme),
      ],
    );

    // Don't add swipe gesture for already completed sets
    if (widget.set.isCompleted) {
      return rowContent;
    }

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: ClipRect(
        child: Stack(
          children: [
            _buildSwipeBackground(),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: rowContent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, Color statusColor) {
    return PopupMenuButton<SetStatus>(
      onSelected: (status) {
        HapticFeedback.lightImpact();
        widget.onStatusChanged(status);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => SetStatus.values.map((status) {
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getStatusIndicator(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(_getStatusLabel(status), style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            _getStatusIndicator(widget.set.status),
            style: TextStyle(
              color: widget.set.status == SetStatus.normal && !widget.set.isCompleted
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(SetStatus status) {
    switch (status) {
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

  Widget _buildWeightInput(ThemeData theme) {
    final isFocused = widget.isActive &&
        widget.focusedField?.isWeight == true &&
        widget.focusedField?.setId == widget.set.id;

    final displayText = isFocused
        ? widget.activeText
        : _formatWeight(widget.set.weight);

    return GestureDetector(
      onTapDown: (_) {
        _clearError();
        widget.onFocus(SessionFocusField.weight(widget.set.id));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        decoration: BoxDecoration(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepsInput(ThemeData theme) {
    final isFocused = widget.isActive &&
        widget.focusedField?.isReps == true &&
        widget.focusedField?.setId == widget.set.id;
    
    final displayText = isFocused
        ? widget.activeText
        : _formatReps(widget.set.reps);

    return GestureDetector(
      onTapDown: (_) {
        _clearError();
        widget.onFocus(SessionFocusField.reps(widget.set.id));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        decoration: BoxDecoration(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTempoInput(ThemeData theme) {
    final isFocused = widget.isActive &&
        widget.focusedField?.isTempo == true &&
        widget.focusedField?.setId == widget.set.id;

    final hasValue = widget.set.tempo != null && widget.set.tempo!.isNotEmpty;
    final displayText = isFocused
        ? widget.activeText
        : (hasValue ? widget.set.tempo! : 'Tempo');

    return GestureDetector(
      onTapDown: (_) {
        _clearError();
        widget.onFocus(SessionFocusField.tempo(widget.set.id));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        width: 60,
        decoration: BoxDecoration(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                displayText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: isFocused
                      ? theme.colorScheme.primary
                      : (hasValue
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ),
              ),
              if (isFocused)
                Positioned(
                  right: 2,
                  child: _BlinkingCursor(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRpeButton(ThemeData theme) {
    final hasRpe = widget.set.rpe != null && widget.set.rpe! > 0;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFocus(SessionFocusField.rpe(widget.set.id));
      },
      child: Container(
        height: 36,
        width: 44,
        decoration: BoxDecoration(
          color: hasRpe
              ? theme.colorScheme.secondary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: hasRpe ? Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)) : null,
        ),
        child: Center(
          child: Text(
            hasRpe ? widget.set.rpe!.toStringAsFixed(hasRpe && widget.set.rpe! % 1 == 0 ? 0 : 1) : '-',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: hasRpe ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionToggle(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Validate reps before completing
        if (widget.set.reps == null || widget.set.reps! <= 0) {
          HapticFeedback.mediumImpact(); // error notification equivalent
          setState(() => _showError = true);
          return;
        }
        HapticFeedback.mediumImpact();
        widget.onComplete();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: widget.set.isCompleted 
              ? Colors.green 
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.set.isCompleted ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: widget.set.isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Widget _buildRestTimerRow(ThemeData theme) {
    final seconds = widget.activeRestSeconds ?? 0;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16),
      child: Row(
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.orange,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.stop_circle, size: 20),
            color: Colors.orange,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: widget.onStopRest,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousDataRow(ThemeData theme) {
    final prev = widget.previousSet;
    if (prev == null || !prev.hasData) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 2),
      child: Row(
        children: [
          if (prev.weight != null && prev.weight! > 0) ...[
            Text(
              '${prev.weight!.toStringAsFixed(prev.weight! % 1 == 0 ? 0 : 1)} kg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (prev.reps != null && prev.reps! > 0)
            Text(
              '${prev.reps} reps',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasPreviousData {
    final prev = widget.previousSet;
    return prev != null && ((prev.weight ?? 0) > 0 || (prev.reps ?? 0) > 0);
  }

  String _formatWeight(double? weight) {
    if (weight == null || weight == 0) return '-';
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
  }

  String _formatReps(int? reps) {
    if (reps == null || reps == 0) return '-';
    return reps.toString();
  }
}

/// Blinking cursor indicator shown when the tempo input is focused.
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
      child: Container(
        width: 2,
        height: 14,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}