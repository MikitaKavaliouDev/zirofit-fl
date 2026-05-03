import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchPendingEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    final events = state.pendingEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminProvider.notifier).fetchPendingEvents(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).fetchPendingEvents(),
        child: _buildBody(theme, state, events),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AdminState state, List<dynamic> events) {
    if (state.isLoading && events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No pending events', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return _buildEventsList(theme, state);
  }

  Widget _buildEventsList(ThemeData theme, AdminState state) {
    final dateFormat = DateFormat('MMM d, yyyy – HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.pendingEvents.length,
      itemBuilder: (context, index) {
        final event = state.pendingEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${event.trainerId}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${dateFormat.format(event.startTime)} – '
                        '${dateFormat.format(event.endTime)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => _confirmModerate(event.id, 'reject'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => _moderateEvent(event.id, 'approve'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moderateEvent(String id, String action) async {
    await ref.read(adminProvider.notifier).moderateEvent(id, action);
  }

  Future<void> _confirmModerate(String id, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action == 'reject' ? 'Reject' : 'Approve'} Event'),
        content: Text(
          action == 'reject'
              ? 'Are you sure you want to reject this event?'
              : 'Are you sure you want to approve this event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action == 'reject' ? 'Reject' : 'Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _moderateEvent(id, action);
    }
  }
}
