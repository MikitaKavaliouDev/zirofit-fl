import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Payouts Settings Screen (Trainer-only)
// ---------------------------------------------------------------------------

/// Displays payout history, Stripe Connect status, bank account details,
/// and earnings summary for the trainer.
class PayoutsSettingsScreen extends ConsumerStatefulWidget {
  const PayoutsSettingsScreen({super.key});

  @override
  ConsumerState<PayoutsSettingsScreen> createState() =>
      _PayoutsSettingsScreenState();
}

class _PayoutsSettingsScreenState extends ConsumerState<PayoutsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(billingProvider.notifier).fetchPayouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(BillingState state, ThemeData theme) {
    // Full-screen loading (first load, no cached data)
    if (state.isLoading && state.payouts.isEmpty && state.stripeStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Full-screen error (no cached data)
    if (state.error != null && state.payouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(billingProvider.notifier).fetchPayouts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(billingProvider.notifier).fetchPayouts(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // -- Earnings Summary --
          _EarningsSummaryCard(
            totalEarned: state.totalEarned,
            pendingAmount: state.pendingAmount,
            paidOutAmount: state.paidOutAmount,
          ),
          const SizedBox(height: 20),

          // -- Bank Account / Stripe Connect --
          _BankAccountCard(
            stripeStatus: state.stripeStatus,
            isLoading: state.isLoading,
            onConnect: _connectStripe,
            onRefresh: () =>
                ref.read(billingProvider.notifier).fetchStripeStatus(),
            onOpenDashboard: () => _openStripeDashboard(state.stripeStatus),
          ),
          const SizedBox(height: 24),

          // -- Payout History --
          const _SectionHeader(icon: Icons.history, title: 'Payout History'),
          const SizedBox(height: 12),
          if (state.payouts.isEmpty)
            const _EmptyPayouts()
          else
            ...state.payouts.map(
              (payout) => _PayoutCard(payout: payout),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stripe Connect Actions
  // ---------------------------------------------------------------------------

  Future<void> _connectStripe() async {
    final notifier = ref.read(billingProvider.notifier);
    final url = await notifier.getStripeOnboardingUrl();

    if (url != null && context.mounted) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start Stripe onboarding. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openStripeDashboard(
    Map<String, dynamic>? stripeStatus,
  ) async {
    final url = stripeStatus?['dashboard_url'] as String? ??
        stripeStatus?['login_url'] as String?;
    if (url != null && context.mounted) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard URL not available.'),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Section Header (shared pattern across all settings screens)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Earnings Summary Card
// ---------------------------------------------------------------------------

class _EarningsSummaryCard extends StatelessWidget {
  final double totalEarned;
  final double pendingAmount;
  final double paidOutAmount;

  const _EarningsSummaryCard({
    required this.totalEarned,
    required this.pendingAmount,
    required this.paidOutAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Earnings Summary',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Total Earned',
                    value: '\$${totalEarned.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Pending',
                    value: '\$${pendingAmount.toStringAsFixed(2)}',
                    icon: Icons.hourglass_empty,
                    color: Colors.orange.shade600,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Paid Out',
                    value: '\$${paidOutAmount.toStringAsFixed(2)}',
                    icon: Icons.check_circle,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bank Account / Stripe Connect Card
// ---------------------------------------------------------------------------

class _BankAccountCard extends StatelessWidget {
  final Map<String, dynamic>? stripeStatus;
  final bool isLoading;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;
  final VoidCallback onOpenDashboard;

  const _BankAccountCard({
    this.stripeStatus,
    required this.isLoading,
    required this.onConnect,
    required this.onRefresh,
    required this.onOpenDashboard,
  });

  /// Derives the onboarding status from the Stripe account data.
  String get _onboardingStatus {
    if (stripeStatus == null) return 'Not Connected';
    final chargesEnabled = stripeStatus!['charges_enabled'] == true;
    final detailsSubmitted = stripeStatus!['details_submitted'] == true;
    if (chargesEnabled) return 'Connected';
    if (detailsSubmitted) return 'Pending Verification';
    return 'Not Connected';
  }

  bool get _isComplete => _onboardingStatus == 'Connected';
  bool get _isPending => _onboardingStatus == 'Pending Verification';

  Color get _statusColor {
    if (_isComplete) return Colors.green.shade600;
    if (_isPending) return Colors.orange.shade600;
    return Colors.grey;
  }

  IconData get _statusIcon {
    if (_isComplete) return Icons.check_circle;
    if (_isPending) return Icons.hourglass_empty;
    return Icons.link_off;
  }

  /// Extracts the bank last 4 digits from the Stripe connect status.
  /// Supports multiple response shapes from the Stripe API.
  String? get _bankLast4 {
    if (stripeStatus == null) return null;

    // Direct key
    final direct = stripeStatus!['bank_last4'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    // Nested under external_accounts (Stripe Connect standard shape)
    final external = stripeStatus!['external_accounts'] as Map<String, dynamic>?;
    if (external != null) {
      final data = external['data'] as List<dynamic>?;
      if (data != null && data.isNotEmpty) {
        final account = data[0] as Map<String, dynamic>?;
        final last4 = account?['last4'] as String?;
        if (last4 != null && last4.isNotEmpty) return last4;
      }
    }

    return null;
  }

  /// Extracts the bank name from Stripe status.
  String? get _bankName {
    if (stripeStatus == null) return null;

    final direct = stripeStatus!['bank_name'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final external = stripeStatus!['external_accounts'] as Map<String, dynamic>?;
    if (external != null) {
      final data = external['data'] as List<dynamic>?;
      if (data != null && data.isNotEmpty) {
        final account = data[0] as Map<String, dynamic>?;
        final bankName = account?['bank_name'] as String?;
        if (bankName != null && bankName.isNotEmpty) return bankName;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last4 = _bankLast4;
    final bankName = _bankName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header row --
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 22,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Account',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_statusIcon, size: 16, color: _statusColor),
                          const SizedBox(width: 6),
                          Text(
                            _onboardingStatus,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 22),
                  tooltip: 'Refresh status',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            // -- Bank account details (when connected) --
            if (_isComplete && last4 != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bankName != null)
                            Text(
                              bankName,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          Text(
                            '•••• $last4',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Connect your bank account via Stripe to receive payments for your packages, services, and sessions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // -- Connect / Manage button --
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : (_isComplete ? null : onConnect),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isComplete ? Icons.settings : Icons.link),
                label: Text(
                  _isComplete
                      ? 'Manage Bank Account'
                      : 'Connect Bank Account',
                ),
              ),
            ),

            // -- Dashboard link (when connected) --
            if (_isComplete) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenDashboard,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Stripe Dashboard'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payout Card (individual payout entry)
// ---------------------------------------------------------------------------

class _PayoutCard extends StatelessWidget {
  final Payout payout;

  const _PayoutCard({required this.payout});

  String get _statusLabel {
    switch (payout.status) {
      case 'paid':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return payout.status.toUpperCase();
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (payout.status) {
      case 'paid':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'failed':
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (payout.status) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${payout.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(payout.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(
                _statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Empty State (no payouts yet)
// ---------------------------------------------------------------------------

class _EmptyPayouts extends StatelessWidget {
  const _EmptyPayouts();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No payouts yet',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Once your earnings are processed, they will\nappear here as completed payouts.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
