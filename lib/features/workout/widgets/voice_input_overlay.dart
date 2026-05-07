import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';

/// ---------------------------------------------------------------------------
/// VoiceInputOverlay
/// ---------------------------------------------------------------------------

/// A modal bottom sheet that listens for a voice command, shows the recognised
/// text, parses it, and lets the user confirm or cancel the result.
///
/// Usage:
/// ```dart
/// final result = await VoiceInputOverlay.show(context, service: myService);
/// if (result != null) { /* log the set */ }
/// ```
class VoiceInputOverlay extends StatefulWidget {
  const VoiceInputOverlay({
    super.key,
    required this.service,
    this.knownExercises = const [],
  });

  /// The voice-log service used for recognition and parsing.
  final VoiceLogService service;

  /// Optional list of known exercise names to improve NLP accuracy.
  final List<String> knownExercises;

  /// Shows the overlay as a modal bottom sheet.
  ///
  /// Returns a [ParsedVoiceInput] if the user confirmed, or `null` on cancel.
  static Future<ParsedVoiceInput?> show(
    BuildContext context, {
    required VoiceLogService service,
    List<String> knownExercises = const [],
  }) {
    return showModalBottomSheet<ParsedVoiceInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VoiceInputOverlay(
        service: service,
        knownExercises: knownExercises,
      ),
    );
  }

  @override
  State<VoiceInputOverlay> createState() => _VoiceInputOverlayState();
}

/// Internal states the overlay can be in.
enum _VoiceOverlayPhase { listening, processing, result, error }

class _VoiceInputOverlayState extends State<VoiceInputOverlay>
    with SingleTickerProviderStateMixin {
  _VoiceOverlayPhase _phase = _VoiceOverlayPhase.listening;
  String _recognizedText = '';
  ParsedVoiceInput? _parsed;
  String _errorText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start listening after a short frame delay so the sheet is visible first.
    Future.microtask(_startListening);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.service.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      final text = await widget.service.startListening();

      if (!mounted) return;

      if (text == null || text.trim().isEmpty) {
        setState(() {
          _phase = _VoiceOverlayPhase.error;
          _errorText = 'No speech detected. Please try again.';
        });
        return;
      }

      setState(() {
        _recognizedText = text;
        _phase = _VoiceOverlayPhase.processing;
      });

      // Brief processing delay for UX
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      final parsed = widget.service.parse(
        text,
        knownExercises: widget.knownExercises,
      );

      if (parsed == null) {
        setState(() {
          _phase = _VoiceOverlayPhase.error;
          _errorText =
              'Could not understand the command.\n'
              'Try: "Bench press 5 reps 135 pounds"';
        });
      } else {
        setState(() {
          _parsed = parsed;
          _phase = _VoiceOverlayPhase.result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _VoiceOverlayPhase.error;
        _errorText = 'Speech recognition error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Grab handle ──
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

            // ── Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Voice Log',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Speak your set details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // ── Content varies by phase ──
            _buildPhaseContent(theme),

            const SizedBox(height: 32),

            // ── Bottom actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildActions(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent(ThemeData theme) {
    switch (_phase) {
      case _VoiceOverlayPhase.listening:
        return _buildListeningContent(theme);
      case _VoiceOverlayPhase.processing:
        return _buildProcessingContent(theme);
      case _VoiceOverlayPhase.result:
        return _buildResultContent(theme);
      case _VoiceOverlayPhase.error:
        return _buildErrorContent(theme);
    }
  }

  // ── Listening ──

  Widget _buildListeningContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Listening...',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (_recognizedText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '"$_recognizedText"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ── Processing ──

  Widget _buildProcessingContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        Text(
          'Processing...',
          style: theme.textTheme.titleMedium,
        ),
        if (_recognizedText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '"$_recognizedText"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // ── Result ──

  Widget _buildResultContent(ThemeData theme) {
    final parsed = _parsed!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raw text
          Text(
            'Recognised:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"$parsed->rawText"',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),

          // Exercise name
          if (parsed.exerciseName != null) ...[
            _buildResultRow(
              theme,
              icon: Icons.fitness_center,
              label: 'Exercise',
              value: parsed.exerciseName!,
            ),
            const SizedBox(height: 12),
          ],

          // Reps
          _buildResultRow(
            theme,
            icon: Icons.replay,
            label: 'Reps',
            value: '${parsed.reps}',
          ),

          // Weight
          if (parsed.weight != null) ...[
            const SizedBox(height: 12),
            _buildResultRow(
              theme,
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: '${parsed.weight!.toStringAsFixed(1)} kg',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label:  ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Error ──

  Widget _buildErrorContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_off,
            size: 40,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ──

  Widget _buildActions(ThemeData theme) {
    switch (_phase) {
      case _VoiceOverlayPhase.listening:
      case _VoiceOverlayPhase.processing:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  widget.service.stopListening();
                  // Manually trigger processing with whatever was recognised
                  if (_recognizedText.isNotEmpty) {
                    setState(() => _phase = _VoiceOverlayPhase.processing);
                    _finishWithText(_recognizedText);
                  } else {
                    setState(() {
                      _phase = _VoiceOverlayPhase.error;
                      _errorText = 'No speech detected. Please try again.';
                    });
                  }
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          ],
        );

      case _VoiceOverlayPhase.result:
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_parsed),
                icon: const Icon(Icons.check),
                label: const Text('Log Set'),
              ),
            ),
          ],
        );

      case _VoiceOverlayPhase.error:
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _phase = _VoiceOverlayPhase.listening;
                    _errorText = '';
                    _recognizedText = '';
                  });
                  Future.microtask(_startListening);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _finishWithText(String text) async {
    setState(() {
      _recognizedText = text;
    });

    // Brief processing delay for UX
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final parsed = widget.service.parse(
      text,
      knownExercises: widget.knownExercises,
    );

    setState(() {
      if (parsed == null) {
        _phase = _VoiceOverlayPhase.error;
        _errorText =
            'Could not understand the command.\n'
            'Try: "Bench press 5 reps 135 pounds"';
      } else {
        _parsed = parsed;
        _phase = _VoiceOverlayPhase.result;
      }
    });
  }
}
