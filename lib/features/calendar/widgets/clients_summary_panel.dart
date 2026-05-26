import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';

/// A collapsible panel showing which clients have sessions on the selected date.
///
/// Extracts unique clients from [events] filtered by [selectedDate] and displays
/// each client name with their session count for that day. Tapping a client
/// invokes [onClientTap] with the client's ID and name.
class ClientsSummaryPanel extends StatefulWidget {
  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final void Function(String clientId, String clientName)? onClientTap;

  const ClientsSummaryPanel({
    super.key,
    required this.events,
    required this.selectedDate,
    this.onClientTap,
  });

  @override
  State<ClientsSummaryPanel> createState() => _ClientsSummaryPanelState();
}

class _ClientsSummaryPanelState extends State<ClientsSummaryPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  /// Events that fall on the selected date.
  List<CalendarEvent> get _dayEvents {
    return widget.events.where((event) {
      return event.startTime.year == widget.selectedDate.year &&
          event.startTime.month == widget.selectedDate.month &&
          event.startTime.day == widget.selectedDate.day;
    }).toList();
  }

  /// Grouped client summaries with session counts for the selected date.
  List<_ClientSummary> get _clientSummaries {
    final map = <String, _ClientSummary>{};
    for (final event in _dayEvents) {
      // Key by clientId when available, fall back to clientName
      final key = event.clientId ?? event.clientName ?? '_unknown';
      if (map.containsKey(key)) {
        map[key] = _ClientSummary(
          clientId: map[key]!.clientId,
          clientName: map[key]!.clientName,
          count: map[key]!.count + 1,
        );
      } else {
        map[key] = _ClientSummary(
          clientId: event.clientId,
          clientName: event.clientName ?? 'Unknown Client',
          count: 1,
        );
      }
    }
    return map.values.toList()
      ..sort((a, b) => a.clientName.compareTo(b.clientName));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaries = _clientSummaries;
    final uniqueCount = summaries.length;

    // Don't render anything if there are no clients for this date.
    if (uniqueCount == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header bar ──────────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Clients ($uniqueCount)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Collapsed hint
                AnimatedOpacity(
                  opacity: _isExpanded ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    uniqueCount == 1
                        ? '1 client today'
                        : '$uniqueCount clients today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // ── Expandable client list ──────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: summaries.map((summary) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          summary.clientName.isNotEmpty
                              ? summary.clientName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        summary.clientName,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${summary.count}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: summary.clientId != null
                          ? () => widget.onClientTap?.call(
                                summary.clientId!,
                                summary.clientName,
                              )
                          : null,
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),

        // Separator before the day-sessions list below
        const Divider(height: 1),
      ],
    );
  }
}

/// Internal data class for a grouped client summary.
class _ClientSummary {
  final String? clientId;
  final String clientName;
  final int count;

  const _ClientSummary({
    this.clientId,
    required this.clientName,
    required this.count,
  });
}
