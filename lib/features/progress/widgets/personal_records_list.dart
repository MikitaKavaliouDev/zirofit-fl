import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// List of recent personal records with exercise, value, and date.
///
/// Mirrors iOS Personal Records widget.
class PersonalRecordsList extends StatelessWidget {
  final List<AnalyticsPersonalRecord> prs;

  const PersonalRecordsList({super.key, required this.prs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (prs.isEmpty) {
      return Center(
        child: Text(
          'No records yet',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    final displayPrs = prs.take(5).toList();

    return Column(
      children: displayPrs.asMap().entries.map((entry) {
        final pr = entry.value;
        final isLast = entry.key == displayPrs.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr.exercise,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.yMMMd().format(pr.date),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pr.value.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'PR',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
          ],
        );
      }).toList(),
    );
  }
}
