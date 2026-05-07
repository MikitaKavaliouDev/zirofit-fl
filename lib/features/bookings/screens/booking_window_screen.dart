import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_settings_provider.dart';

// ---------------------------------------------------------------------------
// Booking Window Screen
// ---------------------------------------------------------------------------

class BookingWindowScreen extends ConsumerStatefulWidget {
  const BookingWindowScreen({super.key});

  @override
  ConsumerState<BookingWindowScreen> createState() =>
      _BookingWindowScreenState();
}

class _BookingWindowScreenState extends ConsumerState<BookingWindowScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Window'),
      ),
      body: Column(
        children: [
          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Control how far in advance clients can book and how much time you need between sessions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Loading
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),

          // Picker cards
          if (!state.isLoading)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: [
                  _ValuePickerCard(
                    icon: Icons.schedule,
                    title: 'Advance Notice',
                    subtitle:
                        'Minimum hours before a session a client can book',
                    value: state.advanceNotice,
                    unit: 'hours',
                    min: 2,
                    max: 72,
                    onChanged: (v) => ref
                        .read(bookingSettingsProvider.notifier)
                        .updateAdvanceNotice(v),
                  ),
                  const SizedBox(height: 12),
                  _ValuePickerCard(
                    icon: Icons.calendar_month,
                    title: 'Booking Horizon',
                    subtitle:
                        'Maximum days in advance clients can book sessions',
                    value: state.bookingHorizon,
                    unit: 'days',
                    min: 7,
                    max: 90,
                    onChanged: (v) => ref
                        .read(bookingSettingsProvider.notifier)
                        .updateBookingHorizon(v),
                  ),
                  const SizedBox(height: 12),
                  _ValuePickerCard(
                    icon: Icons.timer_outlined,
                    title: 'Buffer Time',
                    subtitle:
                        'Time gap between consecutive sessions (minutes)',
                    value: state.bufferMinutes,
                    unit: 'min',
                    min: 0,
                    max: 120,
                    step: 5,
                    onChanged: (v) => ref
                        .read(bookingSettingsProvider.notifier)
                        .updateBufferMinutes(v),
                  ),
                ],
              ),
            ),

          // Messages
          if (state.successMessage != null)
            _MessageBanner(
              message: state.successMessage!,
              type: _MessageType.success,
              onDismiss: () =>
                  ref.read(bookingSettingsProvider.notifier).clearMessages(),
            ),
          if (state.error != null)
            _MessageBanner(
              message: state.error!,
              type: _MessageType.error,
              onDismiss: () =>
                  ref.read(bookingSettingsProvider.notifier).clearMessages(),
            ),
        ],
      ),
      bottomNavigationBar: _SaveButton(
        isSaving: state.isSaving,
        onSave: () => _saveSettings(ref),
      ),
    );
  }

  Future<void> _saveSettings(WidgetRef ref) async {
    final success =
        await ref.read(bookingSettingsProvider.notifier).saveSettings();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking window settings saved')),
      );
      Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Value Picker Card
// ---------------------------------------------------------------------------

class _ValuePickerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _ValuePickerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Value display + stepper
            Row(
              children: [
                // Minus button
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: value > min ? () => onChanged(value - step) : null,
                ),
                const SizedBox(width: 16),

                // Value
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$value',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          unit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Plus button
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: value < max ? () => onChanged(value + step) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper Button
// ---------------------------------------------------------------------------

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return Material(
      color: isDisabled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: isDisabled
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save Button (bottom bar)
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveButton({
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Banner
// ---------------------------------------------------------------------------

enum _MessageType { success, error }

class _MessageBanner extends StatelessWidget {
  final String message;
  final _MessageType type;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = type == _MessageType.error;

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: isError
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      leading: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onPrimaryContainer,
      ),
      content: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
