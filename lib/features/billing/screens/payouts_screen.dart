import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Payouts Screen
// ---------------------------------------------------------------------------

/// Displays payout history, Stripe Connect status, and earnings summary.
class PayoutsScreen extends ConsumerStatefulWidget {
  const PayoutsScreen({super.key});

  @override
  ConsumerState<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends ConsumerState<PayoutsScreen> {
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
      appBar: AppBar(title: const Text('Payouts')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(BillingState state, ThemeData theme) {
    if (state.isLoading && state.payouts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.payouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
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
        padding: const EdgeInsets.all(16),
        children: [
          // -- Summary Cards --
          _SummaryRow(
            totalEarned: state.totalEarned,
            pendingAmount: state.pendingAmount,
            paidOutAmount: state.paidOutAmount,
            currency: 'USD',
          ),
          const SizedBox(height: 20),

          // -- Stripe Connect Card --
          _StripeConnectCard(
            stripeStatus: state.stripeStatus,
            isLoading: state.isLoading,
            onConnect: () => _connectStripe(context),
          ),
          const SizedBox(height: 20),

          // -- Payout History --
          Text(
            'Payout History',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (state.payouts.isEmpty)
            const _EmptyState(
              icon: Icons.account_balance,
              message: 'No payouts yet',
              subtitle: 'Payouts will appear here once processed',
            )
          else
            ...state.payouts.map(
              (payout) => _PayoutCard(payout: payout),
            ),
        ],
      ),
    );
  }

  Future<void> _connectStripe(BuildContext context) async {
    final notifier = ref.read(billingProvider.notifier);
    final url = await notifier.fetchStripeOnboardingUrl();

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
}

// ---------------------------------------------------------------------------
// Summary Row
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  final double totalEarned;
  final double pendingAmount;
  final double paidOutAmount;
  final String currency;

  const _SummaryRow({
    required this.totalEarned,
    required this.pendingAmount,
    required this.paidOutAmount,
    required this.currency,
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
            Text(
              'Earnings Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Earned',
                    value: _formatAmount(totalEarned, currency),
                    icon: Icons.trending_up,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Pending',
                    value: _formatAmount(pendingAmount, currency),
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Paid Out',
                    value: _formatAmount(paidOutAmount, currency),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
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
// Stripe Connect Card
// ---------------------------------------------------------------------------

class _StripeConnectCard extends StatelessWidget {
  final Map<String, dynamic>? stripeStatus;
  final bool isLoading;
  final VoidCallback onConnect;

  const _StripeConnectCard({
    this.stripeStatus,
    required this.isLoading,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected =
        stripeStatus?['charges_enabled'] == true;
    final detailsSubmitted =
        stripeStatus?['details_submitted'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stripe Connect',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isConnected
                            ? 'Connected & Ready'
                            : detailsSubmitted
                                ? 'Pending Activation'
                                : 'Not Connected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isConnected
                              ? Colors.green
                              : detailsSubmitted
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your bank account via Stripe to receive payments for your packages and services directly.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onConnect, // ignore: prefer_const_constructors
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  isConnected
                      ? 'Manage Stripe Account'
                      : 'Connect Stripe Account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payout Card
// ---------------------------------------------------------------------------

class _PayoutCard extends StatelessWidget {
  final Payout payout;

  const _PayoutCard({required this.payout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = payout.status == 'paid';
    final statusColor = isPositive ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.pending,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${payout.currency} ${payout.amount.toStringAsFixed(2)}',
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
                payout.status.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
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
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
