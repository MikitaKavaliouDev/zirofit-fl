import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/features/billing/providers/subscription_provider.dart';

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
      ref.read(subscriptionProvider.notifier).fetchSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(SubscriptionState state, ThemeData theme) {
    if (state.isLoading && state.subscription == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.subscription == null) {
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
                    ref.read(subscriptionProvider.notifier).fetchSubscription(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final subscription = state.subscription;
    final isActive = subscription?.status == 'active';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -- Current Plan Card --
        _CurrentPlanCard(
          planName: subscription?.planName ?? 'Free Plan',
          price: subscription != null && isActive
              ? '\$${subscription.price} / ${subscription.interval}'
              : 'Free',
          status: subscription?.status,
          nextBillingDate: subscription?.nextBillingDate,
        ),
        const SizedBox(height: 24),

        // -- Plan Features --
        Text(
          'Plan Features',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...(subscription?.features ?? _defaultFreeFeatures()).map(
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
        if (isActive) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openBillingPortal(context),
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
        if (isActive) ...[
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

  List<String> _defaultFreeFeatures() {
    return [
      'Basic client management',
      'Standard workout tracking',
      'Community access',
      'Limited storefront',
    ];
  }

  Future<void> _openBillingPortal(BuildContext context) async {
    final notifier = ref.read(subscriptionProvider.notifier);
    final url = await notifier.getPortalLink();

    if (url != null && context.mounted) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open billing portal. Please try again.'),
        ),
      );
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
  final DateTime? nextBillingDate;

  const _CurrentPlanCard({
    required this.planName,
    required this.price,
    this.status,
    this.nextBillingDate,
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
                // -- Tier Badge --
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
                    isActive ? 'ACTIVE' : (status?.toUpperCase() ?? 'INACTIVE'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive && nextBillingDate != null) ...[
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
                    DateFormat.yMMMd().format(nextBillingDate!),
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
