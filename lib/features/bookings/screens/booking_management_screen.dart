import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/bookings/providers/bookings_provider.dart';
import 'package:zirofit_fl/features/bookings/screens/working_hours_screen.dart';

// ---------------------------------------------------------------------------
// Booking Management Screen
// ---------------------------------------------------------------------------

class BookingManagementScreen extends ConsumerStatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  ConsumerState<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState
    extends ConsumerState<BookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Confirmed', 'Declined'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(bookingsProvider.notifier).fetchBookings(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: _tabs.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: _Body(tabController: _tabController),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (separated so it can watch the provider)
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  final TabController tabController;

  const _Body({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);
    final theme = Theme.of(context);

    if (state.isLoading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load bookings', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(bookingsProvider.notifier).fetchBookings(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: tabController,
      children: [
        _buildTabContent(state, null, theme, ref),
        _buildTabContent(state, BookingStatus.pending, theme, ref),
        _buildTabContent(state, BookingStatus.confirmed, theme, ref),
        _buildTabContent(state, BookingStatus.cancelled, theme, ref),
      ],
    );
  }

  Widget _buildTabContent(
    BookingsState state,
    BookingStatus? filterStatus,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final filtered = filterStatus == null
        ? state.bookings
        : state.bookings.where((b) => b.status == filterStatus).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filterStatus == BookingStatus.pending
                  ? Icons.hourglass_empty
                  : filterStatus == BookingStatus.confirmed
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              filterStatus == null
                  ? 'No bookings yet'
                  : 'No ${filterStatus.name} bookings',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filterStatus == BookingStatus.pending
                  ? 'New requests will appear here'
                  : filterStatus == null
                      ? 'Create a new booking to get started'
                      : 'No bookings with this status',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingsProvider.notifier).fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          // Settings card at the top
          if (index == 0) {
            return _SettingsCard(
              onWorkingHoursTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WorkingHoursScreen(),
                  ),
                );
              },
            );
          }

          final booking = filtered[index - 1];
          return _BookingCard(
            booking: booking,
            onConfirm: booking.status == BookingStatus.pending
                ? () => _confirmBooking(context, ref, booking.id)
                : null,
            onDecline: booking.status == BookingStatus.pending
                ? () => _declineBooking(context, ref, booking.id)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _confirmBooking(
      BuildContext context, WidgetRef ref, String id) async {
    final success = await ref.read(bookingsProvider.notifier).confirmBooking(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Booking confirmed' : 'Failed to confirm booking',
          ),
        ),
      );
    }
  }

  Future<void> _declineBooking(
      BuildContext context, WidgetRef ref, String id) async {
    final success = await ref.read(bookingsProvider.notifier).declineBooking(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Booking declined' : 'Failed to decline booking',
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Settings card (Working Hours shortcut)
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final VoidCallback onWorkingHoursTap;

  const _SettingsCard({required this.onWorkingHoursTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _SettingsRow(
              icon: Icons.access_time_rounded,
              iconColor: theme.colorScheme.primary,
              title: 'Working Hours',
              subtitle: 'Set your weekly availability',
              onTap: onWorkingHoursTap,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable Booking Card
// ---------------------------------------------------------------------------

class _BookingCard extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;

  const _BookingCard({
    required this.booking,
    this.onConfirm,
    this.onDecline,
  });

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final statusColor = _statusColor(booking.status, theme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main row: always visible
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client avatar placeholder
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 22,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name, date, status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.clientName ??
                                      booking.clientEmail ??
                                      'Unknown Client',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dateFormat.format(booking.startTime)} · ${timeFormat.format(booking.startTime)}–${timeFormat.format(booking.endTime)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(booking.status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Client email
                      if (booking.clientEmail != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          text: booking.clientEmail!,
                          theme: theme,
                        ),
                      ],

                      // Expand indicator
                      const SizedBox(height: 8),
                      Center(
                        child: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded details
                if (_expanded) ...[
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Booking ID
                        _DetailRow(
                          icon: Icons.tag,
                          label: 'Booking ID',
                          value: booking.id,
                          theme: theme,
                        ),

                        // Client info
                        if (booking.clientId != null)
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Client ID',
                            value: booking.clientId!,
                            theme: theme,
                          ),

                        // Created at
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Requested',
                          value: DateFormat('MMM d, yyyy · HH:mm')
                              .format(booking.createdAt),
                          theme: theme,
                        ),

                        // Notes
                        if (booking.clientNotes != null &&
                            booking.clientNotes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Client Notes',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.clientNotes!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Action buttons for pending bookings
                        if (widget.onConfirm != null &&
                            widget.onDecline != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onDecline,
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Decline'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    side: BorderSide(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: widget.onConfirm,
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Confirm'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(BookingStatus status, ThemeData theme) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.cancelled:
        return 'DECLINED';
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
