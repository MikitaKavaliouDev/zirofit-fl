import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Trainer Subscription Screen
// ---------------------------------------------------------------------------

/// Displays the trainer's current subscription plan, upgrade options, billing
/// history, and the ability to manage or cancel the subscription.
class TrainerSubscriptionScreen extends ConsumerStatefulWidget {
  const TrainerSubscriptionScreen({super.key});

  @override
  ConsumerState<TrainerSubscriptionScreen> createState() =>
      _TrainerSubscriptionScreenState();
}

class _TrainerSubscriptionScreenState
    extends ConsumerState<TrainerSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(billingProvider.notifier).fetchSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(BillingState state, ThemeData theme) {
    if (state.isLoading && state.subscriptionStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.subscriptionStatus == null) {
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
                    ref.read(billingProvider.notifier).fetchSubscription(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -- Current Plan Card --
        _CurrentPlanCard(
          planName: _planLabel(state.subscriptionStatus),
          price: _planPrice(state.subscriptionStatus),
          status: state.subscriptionStatus,
          nextBillingDate: 'Feb 28, 2026', // Placeholder
        ),
        const SizedBox(height: 24),

        // -- Plan Features --
        Text(
          'Plan Features',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._planFeatures(state.subscriptionStatus).map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Flexible(child: Text(feature)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // -- Action Buttons --
        if (state.subscriptionStatus == 'active') ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Upgrade options coming soon')),
              ),
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Upgrade Plan'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openBillingPortal(context),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Billing History'),
          ),
        ),
        if (state.subscriptionStatus == 'active') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showCancelConfirmation(context),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: Text(
                'Cancel Subscription',
                style: TextStyle(color: Colors.red.shade400),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _planLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Trainer Pro';
      case 'past_due':
        return 'Trainer Pro (Past Due)';
      case 'canceled':
        return 'Free Plan';
      case 'incomplete':
        return 'Pending Activation';
      default:
        return 'Free Plan';
    }
  }

  String _planPrice(String? status) {
    switch (status) {
      case 'active':
      case 'past_due':
        return '\$29.99 / month';
      default:
        return 'Free';
    }
  }

  List<String> _planFeatures(String? status) {
    if (status == 'active' || status == 'past_due') {
      return [
        'Unlimited client management',
        'Advanced analytics & reporting',
        'Custom storefront & branding',
        'Stripe Connect payouts',
        'Priority support',
        'Marketplace listing',
      ];
    }
    return [
      'Basic client management',
      'Standard workout tracking',
      'Community access',
      'Limited storefront',
    ];
  }

  Future<void> _openBillingPortal(BuildContext context) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>(
        ApiConstants.billingPortal,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      if (url != null && context.mounted) {
        await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open billing portal. Please try again.'),
          ),
        );
      }
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will lose access to Pro features at the end of your '
          'current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cancellation processed. You retain access until the end of the billing period.'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current Plan Card
// ---------------------------------------------------------------------------

class _CurrentPlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final String? status;
  final String nextBillingDate;

  const _CurrentPlanCard({
    required this.planName,
    required this.price,
    this.status,
    required this.nextBillingDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = status == 'active';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status?.toUpperCase() ?? 'INACTIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    'Next billing date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    nextBillingDate,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
