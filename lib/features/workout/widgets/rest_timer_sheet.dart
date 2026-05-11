import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/workout/providers/workout_enhancement_provider.dart';

class RestTimerSheet extends ConsumerStatefulWidget {
  const RestTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Rest Timer',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => const RestTimerSheet(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends ConsumerState<RestTimerSheet>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  int _remainingSeconds = 90;
  bool _isRunning = true;
  int _totalSeconds = 90;
  late final AnimationController _animController;
  late Animation<double> _progressAnimation;

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

    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    _isRunning = true;
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
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _totalSeconds = seconds;
      _isRunning = true;
    });
    _syncProgress();
    _startTimer();
  }

  void _addTime(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _remainingSeconds = (_remainingSeconds + delta).clamp(0, 600);
      if (_remainingSeconds > _totalSeconds) _totalSeconds = _remainingSeconds;
    });
    _syncProgress();
  }

  void _syncProgress() {
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: progress,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ziroBlue = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphism background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                const Spacer(),

                // Timer Display
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final minutes = _remainingSeconds ~/ 60;
                    final seconds = _remainingSeconds % 60;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CircularProgressIndicator(
                            value: _progressAnimation.value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            valueColor: const AlwaysStoppedAnimation(ziroBlue),
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 64,
                              ),
                            ),
                            Text(
                              _isRunning ? 'RESTING' : 'PAUSED',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white60,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(),

                // Presets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [30, 60, 90, 120, 180].map((s) {
                      final isCurrent = _totalSeconds == s;
                      return GestureDetector(
                        onTap: () => _resetTimer(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrent ? ziroBlue : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            '${s}s',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ControlCircle(
                        icon: Icons.remove,
                        label: '-15s',
                        onTap: () => _addTime(-15),
                      ),
                      GestureDetector(
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _ControlCircle(
                        icon: Icons.add,
                        label: '+15s',
                        onTap: () => _addTime(15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Skip Button
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'SKIP REST',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlCircle({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
