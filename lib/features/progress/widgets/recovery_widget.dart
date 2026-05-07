import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';

/// Recovery readiness widget showing sleep, energy, and stress metrics
/// from the user's most recent check-in.
///
/// Displays a mini donut chart for overall readiness (0–10) alongside
/// individual bars for sleep hours, energy level, and inverted stress level.
class RecoveryWidget extends ConsumerWidget {
  const RecoveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(checkInProvider);
    final checkIn = checkInState.lastCheckIn;

    if (checkIn == null) {
      return _buildEmptyState(context);
    }

    final readiness = _calculateReadiness(checkIn);
    final sleepScore = normalizeSleep(checkIn.sleepHours);
    final energyScore = normalizeEnergy(checkIn.energyLevel);
    final stressScore = normalizeStress(checkIn.stressLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mini donut chart with readiness score
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(88, 88),
                  painter: _DonutPainter(
                    score: readiness,
                    scoreColor: _scoreColor(readiness),
                    trackColor: Colors.grey.withValues(alpha: 0.15),
                    thickness: 8,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      readiness.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(readiness),
                          ),
                    ),
                    Text(
                      'Readiness',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Bars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecoveryBar(
                  label: 'Sleep',
                  score: sleepScore,
                  displayValue:
                      '${checkIn.sleepHours?.toStringAsFixed(1) ?? "—"}h',
                  color: _barColor(sleepScore),
                ),
                const SizedBox(height: 10),
                _RecoveryBar(
                  label: 'Energy',
                  score: energyScore,
                  displayValue: '${checkIn.energyLevel ?? "—"}/10',
                  color: _barColor(energyScore),
                ),
                const SizedBox(height: 10),
                _RecoveryBar(
                  label: 'Stress',
                  score: stressScore,
                  displayValue: '${checkIn.stressLevel ?? "—"}/10',
                  color: _barColor(stressScore),
                  inverted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.favorite_outline, size: 32, color: Colors.orange.shade300),
            const SizedBox(height: 12),
            Text(
              'Complete a check-in to see\nyour recovery readiness.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---- Public score helpers (exposed for testing) ----

  /// Calculate overall readiness score (0–10) from check-in data.
  static double _calculateReadiness(CheckIn checkIn) {
    final scores = <double>[
      normalizeSleep(checkIn.sleepHours),
      normalizeEnergy(checkIn.energyLevel),
      normalizeStress(checkIn.stressLevel),
    ];
    if (scores.every((s) => s == 0)) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Normalize sleep hours to 0–10 scale (0h → 0, 8h → 10, >10h capped).
  static double normalizeSleep(double? hours) {
    if (hours == null || hours < 0) return 0;
    return (hours / 8.0 * 10.0).clamp(0.0, 10.0);
  }

  /// Energy level is already on a 1–10 scale.
  static double normalizeEnergy(int? level) {
    if (level == null) return 0;
    return level.toDouble().clamp(0.0, 10.0);
  }

  /// Invert stress so high stress → low score (1→10, 10→0).
  static double normalizeStress(int? level) {
    if (level == null) return 0;
    return (11 - level).toDouble().clamp(0.0, 10.0);
  }

  /// Map a 0–10 score to a color: green (≥7), amber (4–6), red (<4).
  static Color _scoreColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }

  static Color _barColor(double score) {
    if (score >= 7) return const Color(0xFF22C55E); // green-500
    if (score >= 4) return const Color(0xFFF59E0B); // amber-500
    return const Color(0xFFEF4444); // red-500
  }
}

// ---------------------------------------------------------------------------
// Donut chart painter
// ---------------------------------------------------------------------------

class _DonutPainter extends CustomPainter {
  final double score;
  final Color scoreColor;
  final Color trackColor;
  final double thickness;

  _DonutPainter({
    required this.score,
    required this.scoreColor,
    required this.trackColor,
    this.thickness = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - thickness) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // Full track circle
    canvas.drawCircle(center, radius, trackPaint);

    // Score arc
    final sweep = (score / 10.0) * 2 * math.pi;
    const start = -math.pi / 2; // 12 o'clock

    final scorePaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.scoreColor != scoreColor;
}

// ---------------------------------------------------------------------------
// Recovery bar
// ---------------------------------------------------------------------------

class _RecoveryBar extends StatelessWidget {
  final String label;
  final double score;
  final String displayValue;
  final Color color;
  final bool inverted;

  const _RecoveryBar({
    required this.label,
    required this.score,
    required this.displayValue,
    required this.color,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (score / 10.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    // Track
                    Container(
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Fill
                    if (inverted)
                      // For inverted bars, fill from the right
                      Positioned(
                        right: 0,
                        child: Container(
                          width: barWidth * fraction,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: barWidth * fraction,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
