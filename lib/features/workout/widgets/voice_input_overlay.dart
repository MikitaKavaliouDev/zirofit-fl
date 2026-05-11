import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';

class VoiceInputOverlay extends StatefulWidget {
  const VoiceInputOverlay({
    super.key,
    required this.service,
    this.knownExercises = const [],
  });

  final VoiceLogService service;
  final List<String> knownExercises;

  static Future<ParsedVoiceInput?> show(
    BuildContext context, {
    required VoiceLogService service,
    List<String> knownExercises = const [],
  }) {
    return showGeneralDialog<ParsedVoiceInput>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Input',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => VoiceInputOverlay(
        service: service,
        knownExercises: knownExercises,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<VoiceInputOverlay> createState() => _VoiceInputOverlayState();
}

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

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

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final parsed = widget.service.parse(
        text,
        knownExercises: widget.knownExercises,
      );

      if (parsed == null) {
        setState(() {
          _phase = _VoiceOverlayPhase.error;
          _errorText = 'Could not understand. Try: "Squats 10 reps 100 kg"';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full screen blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Top Status / Transcription
                  Expanded(
                    child: Center(
                      child: _buildTranscriptionArea(theme),
                    ),
                  ),

                  // Mic Animation / Action Area
                  _buildBottomContent(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionArea(ThemeData theme) {
    if (_phase == _VoiceOverlayPhase.listening) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Listening...',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Speak your exercise details',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    if (_phase == _VoiceOverlayPhase.processing) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (_phase == _VoiceOverlayPhase.error) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 24),
          Text(
            _errorText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      );
    }

    // Result Phase
    final parsed = _parsed!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGGED SET',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            parsed.exerciseName?.toUpperCase() ?? 'EXERCISE',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ResultPill(label: '${parsed.reps} REPS'),
              if (parsed.weight != null) ...[
                const SizedBox(width: 12),
                _ResultPill(label: '${parsed.weight!.toStringAsFixed(1)} KG'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent(ThemeData theme) {
    if (_phase == _VoiceOverlayPhase.result) {
      return Row(
        children: [
          Expanded(
            child: _ActionCircleButton(
              icon: Icons.close,
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(null),
              color: Colors.white24,
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: _ActionCircleButton(
              icon: Icons.check,
              label: 'Confirm',
              onPressed: () => Navigator.of(context).pop(_parsed),
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    if (_phase == _VoiceOverlayPhase.error) {
      return Center(
        child: _ActionCircleButton(
          icon: Icons.refresh,
          label: 'Try Again',
          onPressed: () {
            setState(() {
              _phase = _VoiceOverlayPhase.listening;
              _errorText = '';
              _recognizedText = '';
            });
            _startListening();
          },
          color: Colors.white24,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse rings
            ...List.generate(3, (index) {
              final scale = 1.0 + (_pulseAnimation.value + index / 3.0) % 1.0;
              final opacity = 1.0 - (_pulseAnimation.value + index / 3.0) % 1.0;
              return Container(
                width: 100 * scale,
                height: 100 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: opacity * 0.5),
                    width: 2,
                  ),
                ),
              );
            }),
            // Central mic button
            GestureDetector(
              onTap: () => widget.service.stopListening(),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 32),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultPill extends StatelessWidget {
  final String label;

  const _ResultPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionCircleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
