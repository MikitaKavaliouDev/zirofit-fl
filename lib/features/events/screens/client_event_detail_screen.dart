import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/client_events_provider.dart';
import 'package:zirofit_fl/features/events/providers/events_provider.dart';

class ClientEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ClientEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<ClientEventDetailScreen> createState() =>
      _ClientEventDetailScreenState();
}

class _ClientEventDetailScreenState
    extends ConsumerState<ClientEventDetailScreen> {
  Event? _fetchedEvent;
  bool _isFetching = false;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    final eventsState = ref.read(eventsProvider);
    final exists = eventsState.events.any((e) => e.id == widget.eventId);
    if (!exists) {
      _isFetching = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchEvent();
      });
    }
  }

  Future<void> _fetchEvent() async {
    final event =
        await ref.read(eventsProvider.notifier).fetchEventById(widget.eventId);
    if (!mounted) return;
    setState(() {
      _isFetching = false;
      if (event != null) {
        _fetchedEvent = event;
      } else {
        _fetchFailed = true;
      }
    });
  }

  Event? _resolveEvent(EventsState eventsState) {
    final fromList =
        eventsState.events.where((e) => e.id == widget.eventId).firstOrNull;
    if (fromList != null) return fromList;
    return _fetchedEvent;
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final clientState = ref.watch(clientEventsProvider);
    final theme = Theme.of(context);

    final event = _resolveEvent(eventsState);

    if (event == null) {
      // Loading state while fetching single event from API
      if (_isFetching) {
        return Scaffold(
          appBar: AppBar(title: const Text('Event Details')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      // Error state if fetch failed
      if (_fetchFailed) {
        return Scaffold(
          appBar: AppBar(title: const Text('Event Details')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load event details.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _fetchEvent,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      // Not found (fallback)
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final isBooked = clientState.bookedEvents.any((e) => e.id == widget.eventId);
    final isLoading = clientState.isLoading;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final spotsLeft = event.capacity - event.enrolledCount;
    final capacityRatio = event.capacity > 0
        ? event.enrolledCount / event.capacity
        : 0.0;

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
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image)),
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
            if (event.description != null &&
                event.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.description!,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            // Trainer name
            if (event.trainer != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.person,
                text: event.trainer!.name ??
                    event.trainer!.username ??
                    'Unknown Trainer',
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
            // Capacity
            _InfoRow(
              icon: Icons.people,
              text: '${event.enrolledCount} / ${event.capacity} enrolled',
            ),
            const SizedBox(height: 8),
            // Spots left
            Text(
              spotsLeft <= 0
                  ? 'Event is full'
                  : capacityRatio > 0.8
                      ? 'Almost full - $spotsLeft spots remaining'
                      : '$spotsLeft spots remaining',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: spotsLeft <= 0
                    ? Colors.red
                    : capacityRatio > 0.8
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Capacity progress bar
            if (event.capacity > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: capacityRatio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    capacityRatio >= 0.8
                        ? Colors.red
                        : capacityRatio >= 0.6
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Error message
            if (clientState.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  clientState.error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Join / Cancel button
            if (isBooked) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed:
                      isLoading ? null : () => _cancelBooking(context, ref),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(isLoading ? 'Cancelling...' : 'Cancel Booking'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: isLoading || spotsLeft <= 0
                      ? null
                      : () => _joinEvent(context, ref),
                  icon: isLoading
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
                    isLoading
                        ? 'Joining...'
                        : spotsLeft > 0
                            ? 'Join Event'
                            : 'Event Full',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Join success message
            if (clientState.joinSuccess) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'You have joined this event!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _joinEvent(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(clientEventsProvider.notifier).joinEvent(widget.eventId);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join event. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(clientEventsProvider.notifier);
    final bookingId = notifier.getBookingId(widget.eventId);

    if (bookingId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found. Please refresh.')),
        );
      }
      return;
    }

    final success = await notifier.cancelBooking(bookingId);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel booking. Please try again.'),
          ),
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
