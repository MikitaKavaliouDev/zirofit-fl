import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Text card showing AI-generated insights based on volume comparison.
///
/// Mirrors iOS Personal Insights widget.
class PersonalInsightsCard extends StatelessWidget {
  final List<VolumePoint> volumeData;

  const PersonalInsightsCard({super.key, required this.volumeData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(Icons.tips_and_updates, size: 28, color: Colors.blue.shade400),
        const SizedBox(height: 12),
        Text(
          _buildInsight(),
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _buildInsight() {
    if (volumeData.length < 2) {
      return 'Log more workouts to see your personalized AI insights and trends here.';
    }

    final last = volumeData.last.volume;
    final prev = volumeData[volumeData.length - 2].volume;
    final diff = last - prev;

    if (diff > 0) {
      return 'You lifted ${diff.toInt()} kg more volume than your previous session! Great progressive overload.';
    } else if (diff < 0) {
      return 'You lifted ${(-diff).toInt()} kg less volume than your previous session. Keep pushing!';
    } else {
      return 'Your total volume matched your last session perfectly. Consistency is key!';
    }
  }
}
