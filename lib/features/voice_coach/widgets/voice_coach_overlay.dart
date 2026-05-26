import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/voice_coach/voice_coach_provider.dart';

// =============================================================================
// Voice Coach Overlay
//
// iOS-aligned in-workout coach overlay matching WorkoutSessionView.swift
// voiceLogOverlay (.coach mode):
//   - Indigo color theme (Color(0xFF4F46E5))
//   - Semi-transparent dark blur background
//   - Waveform visualizer animated from audioLevel
//   - Dialogue bubbles (user right-aligned, coach left-aligned)
//   - Controls: dismiss, record, TTS
// =============================================================================

class VoiceCoachOverlay extends ConsumerStatefulWidget {
  const VoiceCoachOverlay({super.key});

  @override
  ConsumerState<VoiceCoachOverlay> createState() => _VoiceCoachOverlayState();
}

class _VoiceCoachOverlayState extends ConsumerState<VoiceCoachOverlay>
    with SingleTickerProviderStateMixin {
  static const Color _indigo = Color(0xFF4F46E5);

  final ScrollController _scrollController = ScrollController();
  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;

  // Simulated audio level for idle animation
  final double _idleLevel = 0.0;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _waveAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _waveCtrl.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Scroll to bottom of dialogue list.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceCoachProvider);

    // Auto-scroll when dialogue changes
    ref.listen(voiceCoachProvider, (prev, next) {
      if (prev?.dialogueHistory.length != next.dialogueHistory.length) {
        _scrollToBottom();
      }
    });

    return Stack(
      children: [
        // ── Background blur ──
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),

        // ── Main content ──
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // -- Dismiss button (top-right) --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    _CircleButton(
                      icon: Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      bgColor: Colors.white.withValues(alpha: 0.15),
                      size: 36,
                      iconSize: 20,
                      onTap: () {
                        ref.read(voiceCoachProvider.notifier).clearDialogue();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Waveform Visualizer ──
              _buildWaveform(state),

              const SizedBox(height: 8),

              // Status text
              Text(
                _statusText(state),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _indigo.withValues(alpha: 0.9),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Static current transcription (when recording) ──
              if (state.isRecording && state.transcription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      state.transcription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // ── Dialogue bubbles ──
              Expanded(
                child: state.dialogueHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: _indigo.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ask me anything about your workout',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.dialogueHistory.length,
                        itemBuilder: (context, index) {
                          final entry = state.dialogueHistory[index];
                          return _DialogueBubble(
                            text: entry.text,
                            isUser: entry.isUser,
                            isLatest:
                                index == state.dialogueHistory.length - 1,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // ── Coach response text (when not added to history yet) ──
              if (state.coachTextResponse.isNotEmpty &&
                  !state.dialogueHistory.any(
                    (d) =>
                        !d.isUser && d.text == state.coachTextResponse,
                  ))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.coachTextResponse,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // ── Error text ──
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 12),

              // ── Bottom Controls ──
              _buildControls(state),

              const SizedBox(height: 8),

              // ── Powered by ElevenLabs (subtle) ──
              Text(
                'Powered by ElevenLabs',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Waveform Visualizer
  // ---------------------------------------------------------------------------

  Widget _buildWaveform(VoiceCoachState state) {
    const barCount = 7;
    final audioLevel = state.isRecording
        ? state.audioLevel
        : state.isProcessing
            ? 0.3
            : state.isSpeaking
                ? 0.5
                : _idleLevel;

    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _waveAnim,
        builder: (context, _) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (i) {
                // Each bar gets a slightly different phase offset
                final phaseOffset = (i / barCount) * 2 * pi;
                // Combine idle pulse with audio level and phase offset
                final wavePhase = sin(
                  _waveAnim.value * 2 * pi + phaseOffset,
                );
                // Normalize: -1 to 1 → 0.2 to 1.0
                final normalized = (wavePhase + 1) / 2;
                final heightFactor = 0.3 + 0.7 * normalized;
                // Audio level scales the entire animation
                final displayLevel =
                    audioLevel.clamp(0.05, 1.0) * heightFactor;
                final barHeight = 8.0 + 52.0 * displayLevel;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 4,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: _indigo.withValues(
                        alpha: 0.5 + 0.5 * heightFactor,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Controls
  // ---------------------------------------------------------------------------

  Widget _buildControls(VoiceCoachState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Record button
          GestureDetector(
            onTap: () {
              final manager = ref.read(voiceCoachProvider.notifier);
              if (state.isRecording || state.isProcessing) {
                // Stop recording
                manager.setRecording(false);
                manager.setProcessing(true);
                // Simulate processing → response
                _simulateCoachResponse(manager);
              } else {
                manager.setRecording(true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isRecording
                    ? Colors.red
                    : (state.isProcessing ? Colors.grey : _indigo),
                boxShadow: state.isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: state.isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      state.isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(width: 24),

          // TTS speaker button
          GestureDetector(
            onTap: () {
              final manager = ref.read(voiceCoachProvider.notifier);
              if (state.isSpeaking) {
                manager.setSpeaking(false);
              } else if (state.coachTextResponse.isNotEmpty) {
                manager.setSpeaking(true);
                // Auto-stop after a delay (simulating TTS playback)
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    manager.setSpeaking(false);
                  }
                });
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isSpeaking
                    ? _indigo.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                state.isSpeaking
                    ? Icons.volume_up_rounded
                    : Icons.volume_up_outlined,
                color: state.isSpeaking
                    ? _indigo
                    : Colors.white.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _statusText(VoiceCoachState state) {
    if (state.isRecording) return 'LISTENING TO YOU...';
    if (state.isProcessing) return 'THINKING...';
    if (state.isSpeaking) return 'SPEAKING...';
    return 'AI COACH';
  }

  /// Simulates a coach response cycle (for demo purposes).
  void _simulateCoachResponse(VoiceCoachManager manager) {
    final currentTranscription = ref.read(voiceCoachProvider).transcription;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      // Add user dialogue
      if (currentTranscription.isNotEmpty) {
        manager.addUserDialogue(currentTranscription);
      }

      // Set processing → done → add coach response
      manager.setProcessing(false);

      // Simulate coach response
      final coachText = _generateCoachResponse(currentTranscription);
      manager.setCoachResponse(coachText);

      // Auto-add to dialogue after a moment
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        manager.addCoachDialogue(coachText);
      });
    });
  }

  /// Simple mock response generator.
  String _generateCoachResponse(String transcription) {
    if (transcription.isEmpty) {
      return "I'm here to help with your workout. What exercise are you working on?";
    }
    final lower = transcription.toLowerCase();
    if (lower.contains('form') || lower.contains('technique')) {
      return 'Focus on controlled movement. Keep your core braced and maintain a neutral spine throughout the lift. Quality over quantity!';
    }
    if (lower.contains('tired') || lower.contains('hard') || lower.contains('break')) {
      return "You're doing great! Take a deep breath. Remember why you started. Push through this set — you're stronger than you think!";
    }
    if (lower.contains('weight') || lower.contains('heavy') || lower.contains('increase')) {
      return 'Progressive overload is key. Aim for 2.5-5kg increase when you can complete all reps with good form on two consecutive sessions.';
    }
    return 'Great effort! Keep that intensity up. Focus on the mind-muscle connection and controlled negatives for maximum gains.';
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// A small circular button used in the overlay controls.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

/// A single dialogue bubble in the chat.
class _DialogueBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final bool isLatest;

  const _DialogueBubble({
    required this.text,
    required this.isUser,
    this.isLatest = false,
  });

  @override
  State<_DialogueBubble> createState() => _DialogueBubbleState();
}

class _DialogueBubbleState extends State<_DialogueBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _indigo = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isLatest) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment:
                widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                widget.isUser ? 'You' : 'AI Coach',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              // Bubble
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!widget.isUser) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _indigo,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isUser
                            ? _indigo.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(
                            widget.isUser ? 16 : 4,
                          ),
                          bottomRight: Radius.circular(
                            widget.isUser ? 4 : 16,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.isUser ? Colors.white : Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Convenience show function
// =============================================================================

/// Show the coach overlay as a full-screen dialog.
Future<void> showVoiceCoachOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Voice Coach',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const VoiceCoachOverlay();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}
