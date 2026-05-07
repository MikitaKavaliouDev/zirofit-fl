import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/booking.dart';
import 'package:zirofit_fl/data/models/enums/booking_status.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_management_provider.dart';
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

  static const _tabs = ['Pending', 'Confirmed', 'Declined'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() {
      ref.read(bookingManagementProvider.notifier).fetchAll();
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
            onPressed: () =>
                ref.read(bookingManagementProvider.notifier).fetchAll(),
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
    final state = ref.watch(bookingManagementProvider);
    final theme = Theme.of(context);

    if (state.isLoading &&
        state.pendingBookings.isEmpty &&
        state.confirmedBookings.isEmpty &&
        state.declinedBookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null &&
        state.pendingBookings.isEmpty &&
        state.confirmedBookings.isEmpty &&
        state.declinedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load bookings',
                style: theme.textTheme.titleMedium),
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
                  ref.read(bookingManagementProvider.notifier).fetchAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: tabController,
      children: [
        _buildPendingTab(state, theme, ref),
        _buildConfirmedTab(state, theme, ref),
        _buildDeclinedTab(state, theme, ref),
      ],
    );
  }

  Widget _buildPendingTab(
      BookingManagementState state, ThemeData theme, WidgetRef ref) {
    if (state.pendingBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        title: 'No pending bookings',
        subtitle: 'New requests will appear here',
        theme: theme,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingManagementProvider.notifier).fetchAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.pendingBookings.length + 1,
        itemBuilder: (context, index) {
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

          final booking = state.pendingBookings[index - 1];
          return _SwipeableBookingCard(
            booking: booking,
            isActionInProgress: state.isActionInProgress,
            onApprove: () => _confirmApprove(context, ref, booking),
            onDecline: () => _confirmDecline(context, ref, booking),
          );
        },
      ),
    );
  }

  Widget _buildConfirmedTab(
      BookingManagementState state, ThemeData theme, WidgetRef ref) {
    if (state.confirmedBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No confirmed bookings',
        subtitle: 'Approved bookings will appear here',
        theme: theme,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingManagementProvider.notifier).fetchAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.confirmedBookings.length,
        itemBuilder: (context, index) {
          final booking = state.confirmedBookings[index];
          return _BookingDetailCard(booking: booking);
        },
      ),
    );
  }

  Widget _buildDeclinedTab(
      BookingManagementState state, ThemeData theme, WidgetRef ref) {
    if (state.declinedBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cancel_outlined,
        title: 'No declined bookings',
        subtitle: 'Declined bookings will appear here',
        theme: theme,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingManagementProvider.notifier).fetchAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.declinedBookings.length,
        itemBuilder: (context, index) {
          final booking = state.declinedBookings[index];
          return _BookingDetailCard(booking: booking);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Confirmation dialogs
  // ---------------------------------------------------------------------------

  Future<void> _confirmApprove(
      BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Booking'),
        content: Text(
          'Confirm booking for ${booking.clientName ?? booking.clientEmail ?? 'this client'} '
          'on ${DateFormat('MMM d, yyyy').format(booking.startTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success =
        await ref.read(bookingManagementProvider.notifier).approveBooking(booking.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Booking approved' : 'Failed to approve booking',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDecline(
      BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Booking'),
        content: Text(
          'Decline booking for ${booking.clientName ?? booking.clientEmail ?? 'this client'} '
          'on ${DateFormat('MMM d, yyyy').format(booking.startTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success =
        await ref.read(bookingManagementProvider.notifier).declineBooking(booking.id);
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
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
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
// Swipeable Booking Card (for Pending tab)
// ---------------------------------------------------------------------------

class _SwipeableBookingCard extends ConsumerStatefulWidget {
  final Booking booking;
  final bool isActionInProgress;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _SwipeableBookingCard({
    required this.booking,
    required this.isActionInProgress,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  ConsumerState<_SwipeableBookingCard> createState() =>
      _SwipeableBookingCardState();
}

class _SwipeableBookingCardState
    extends ConsumerState<_SwipeableBookingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('booking-${booking.id}'),
        confirmDismiss: (direction) async {
          if (widget.isActionInProgress) return false;

          if (direction == DismissDirection.endToStart) {
            widget.onDecline();
            return false; // We handle UI manually via dialog
          } else if (direction == DismissDirection.startToEnd) {
            widget.onApprove();
            return false; // We handle UI manually via dialog
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cancel, color: Colors.white, size: 32),
        ),
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
                  // Main row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 22,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.clientName ??
                                        booking.clientEmail ??
                                        'Unknown Client',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dateFormat.format(booking.startTime)} · '
                                    '${timeFormat.format(booking.startTime)}–'
                                    '${timeFormat.format(booking.endTime)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Pending badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'PENDING',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Duration
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.endTime.difference(booking.startTime).inMinutes} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

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
                          if (booking.clientEmail != null)
                            _DetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: booking.clientEmail!,
                              theme: theme,
                            ),
                          _DetailRow(
                            icon: Icons.tag,
                            label: 'Booking ID',
                            value: booking.id,
                            theme: theme,
                          ),
                          if (booking.clientId != null)
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'Client ID',
                              value: booking.clientId!,
                              theme: theme,
                            ),
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

                          // Action buttons
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.isActionInProgress
                                      ? null
                                      : widget.onDecline,
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
                                  onPressed: widget.isActionInProgress
                                      ? null
                                      : widget.onApprove,
                                  icon: widget.isActionInProgress
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check, size: 18),
                                  label: Text(widget.isActionInProgress
                                      ? 'Processing...'
                                      : 'Approve'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking Detail Card (for Confirmed/Declined tabs)
// ---------------------------------------------------------------------------

class _BookingDetailCard extends ConsumerStatefulWidget {
  final Booking booking;

  const _BookingDetailCard({required this.booking});

  @override
  ConsumerState<_BookingDetailCard> createState() =>
      _BookingDetailCardState();
}

class _BookingDetailCardState extends ConsumerState<_BookingDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    final isConfirmed = booking.status == BookingStatus.confirmed;
    final statusColor = isConfirmed ? Colors.green : theme.colorScheme.error;
    final statusLabel = isConfirmed ? 'CONFIRMED' : 'DECLINED';

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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.clientName ??
                                      booking.clientEmail ??
                                      'Unknown Client',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dateFormat.format(booking.startTime)} · '
                                  '${timeFormat.format(booking.startTime)}–'
                                  '${timeFormat.format(booking.endTime)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${booking.endTime.difference(booking.startTime).inMinutes} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                        if (booking.clientEmail != null)
                          _DetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: booking.clientEmail!,
                            theme: theme,
                          ),
                        _DetailRow(
                          icon: Icons.tag,
                          label: 'Booking ID',
                          value: booking.id,
                          theme: theme,
                        ),
                        if (booking.clientId != null)
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Client ID',
                            value: booking.clientId!,
                            theme: theme,
                          ),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Requested',
                          value: DateFormat('MMM d, yyyy · HH:mm')
                              .format(booking.createdAt),
                          theme: theme,
                        ),
                        if (booking.clientNotes != null &&
                            booking.clientNotes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme.surfaceContainerHighest
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
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

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
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
