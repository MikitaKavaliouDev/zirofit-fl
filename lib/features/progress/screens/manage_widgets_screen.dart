import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/features/progress/models/analytics_widget_config.dart';
import 'package:zirofit_fl/features/progress/providers/widget_config_provider.dart';

/// Screen to show/hide/reorder analytics widgets.
///
/// Mirrors iOS ManageWidgetsView.
class ManageWidgetsScreen extends ConsumerStatefulWidget {
  const ManageWidgetsScreen({super.key});

  @override
  ConsumerState<ManageWidgetsScreen> createState() => _ManageWidgetsScreenState();
}

class _ManageWidgetsScreenState extends ConsumerState<ManageWidgetsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeWidgets = ref.watch(widgetConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Widgets'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active widgets
          Text(
            'Active Widgets',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (activeWidgets.where((w) => w.isVisible).isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No active widgets',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeWidgets.where((w) => w.isVisible).length,
              onReorder: (oldIndex, newIndex) {
                final visible = activeWidgets.where((w) => w.isVisible).toList();
                final moved = visible.removeAt(oldIndex);
                visible.insert(newIndex, moved);

                // Update order in the full list
                ref.read(widgetConfigProvider.notifier).reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final visible = activeWidgets.where((w) => w.isVisible).toList();
                final widget = visible[index];
                return ListTile(
                  key: ValueKey(widget.type),
                  leading: Icon(
                    _getIconData(widget.type.icon),
                    color: Colors.blue,
                  ),
                  title: Text(widget.type.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {
                      ref
                          .read(widgetConfigProvider.notifier)
                          .removeWidget(widget.type);
                    },
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Available widgets
          Text(
            'Available Widgets',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...AnalyticsWidgetType.values
              .where((type) => !activeWidgets.any((w) => w.type == type && w.isVisible))
              .map((type) => ListTile(
                    leading: Icon(
                      _getIconData(type.icon),
                      color: Colors.grey,
                    ),
                    title: Text(type.displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () {
                        ref.read(widgetConfigProvider.notifier).addWidget(type);
                      },
                    ),
                  )),
          if (AnalyticsWidgetType.values
              .every((type) => activeWidgets.any((w) => w.type == type && w.isVisible)))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'All widgets are active',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'directions_run':
        return Icons.directions_run;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'show_chart':
        return Icons.show_chart;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'tips_and_updates':
        return Icons.tips_and_updates;
      case 'track_changes':
        return Icons.track_changes;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.widgets;
    }
  }
}
