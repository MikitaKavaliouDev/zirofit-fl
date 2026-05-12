import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isJoining = false;
  Event? _fetchedEvent;
  bool _isLoadingEvent = false;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(eventsProvider);
    if (!currentState.events.any((e) => e.id == widget.eventId)) {
      _isLoadingEvent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(eventsProvider.notifier).fetchEventById(widget.eventId).then((event) {
          if (mounted) {
            setState(() {
              _fetchedEvent = event;
              _isLoadingEvent = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final event = state.events.where((e) => e.id == widget.eventId).firstOrNull ?? _fetchedEvent;
    final theme = Theme.of(context);

    if (_isLoadingEvent && event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final spotsLeft = event.capacity - event.enrolledCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Category badge
            if (event.category != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  event.category!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Title
            Text(
              event.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.description!,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            // Trainer
            if (event.trainer?.name != null && event.trainer!.name!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                text: event.trainer!.name!,
              ),
            ],
            const SizedBox(height: 24),
            // Date and time
            _InfoRow(
              icon: Icons.calendar_today,
              text: dateFormat.format(event.startTime),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time,
              text:
                  '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
            ),
            if (event.locationName != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on,
                text: event.locationName!,
              ),
            ],
            if (event.address != null && event.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  event.address!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (event.city != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  event.city!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Price
            _InfoRow(
              icon: Icons.attach_money,
              text: event.price > 0
                  ? '${event.price.toStringAsFixed(2)} ${event.currency}'
                  : 'Free',
            ),
            const SizedBox(height: 8),
            // Capacity with progress bar
            Row(
              children: [
                Icon(Icons.people, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${event.enrolledCount} / ${event.capacity} enrolled',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: event.capacity > 0 ? event.enrolledCount / event.capacity : 0,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  spotsLeft > 0 ? theme.colorScheme.primary : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Spots left
            Text(
              spotsLeft > 0 ? '$spotsLeft spots remaining' : 'Event is full',
              style: theme.textTheme.bodySmall?.copyWith(
                color: spotsLeft > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            // Join button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isJoining || spotsLeft <= 0 ? null : _joinEvent,
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.event_available),
                label: Text(
                  _isJoining
                      ? 'Joining...'
                      : spotsLeft > 0
                          ? 'Join Event'
                          : 'Event Full',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinEvent() async {
    setState(() => _isJoining = true);
    final success =
        await ref.read(eventsProvider.notifier).joinEvent(widget.eventId);
    setState(() => _isJoining = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join event. Please try again.')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
