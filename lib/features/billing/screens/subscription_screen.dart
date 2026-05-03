import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Subscription Screen
// ---------------------------------------------------------------------------

/// Displays the current subscription plan, upgrade options, and a button to
/// manage the subscription via the billing portal.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: _buildBody(context, ref, state, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BillingState state,
    ThemeData theme,
  ) {
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
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      state.subscriptionStatus == 'active'
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: state.subscriptionStatus == 'active'
                          ? Colors.green
                          : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _planLabel(state.subscriptionStatus),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (state.subscriptionStatus != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _planDescription(state.subscriptionStatus!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // -- Upgrade Options --
        Text(
          'Choose Your Plan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _PlanOptionCard(
          name: 'Free',
          price: '\$0',
          features: const [
            'Basic workout tracking',
            'Limited client management',
            'Community access',
          ],
          isCurrentPlan: state.subscriptionStatus == null ||
              state.subscriptionStatus == 'inactive' ||
              state.subscriptionStatus == 'canceled',
          onUpgrade: null, // Already on this plan
        ),
        const SizedBox(height: 12),
        _PlanOptionCard(
          name: 'Pro',
          price: '\$29/mo',
          features: const [
            'Unlimited workout tracking',
            'Full client management',
            'Advanced analytics',
            'Priority support',
          ],
          isCurrentPlan: state.subscriptionStatus == 'active',
          onUpgrade: state.subscriptionStatus == 'active'
              ? null
              : () => _startCheckout(context, ref, 'pro'),
        ),
        const SizedBox(height: 12),
        _PlanOptionCard(
          name: 'Enterprise',
          price: '\$99/mo',
          features: const [
            'Everything in Pro',
            'Team management',
            'Custom branding',
            'Dedicated account manager',
            'API access',
          ],
          isCurrentPlan: false,
          onUpgrade: () => _startCheckout(context, ref, 'enterprise'),
        ),

        const SizedBox(height: 24),

        // -- Manage Subscription Button --
        if (state.subscriptionStatus == 'active')
          OutlinedButton.icon(
            onPressed: () => _openBillingPortal(context, ref),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Manage Subscription'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
      ],
    );
  }

  String _planLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Pro Plan';
      case 'past_due':
        return 'Pro Plan (Past Due)';
      case 'canceled':
        return 'Free Plan';
      case 'incomplete':
        return 'Pending Activation';
      default:
        return 'Free Plan';
    }
  }

  String _planDescription(String status) {
    switch (status) {
      case 'active':
        return 'Your subscription is active. Enjoy all Pro features.';
      case 'past_due':
        return 'Your payment is past due. Please update your billing information.';
      case 'canceled':
        return 'Your subscription has been canceled.';
      case 'incomplete':
        return 'Your subscription is being set up.';
      default:
        return 'You are currently on the Free plan.';
    }
  }

  Future<void> _startCheckout(
    BuildContext context,
    WidgetRef ref,
    String packageId,
  ) async {
    final notifier = ref.read(billingProvider.notifier);
    final url = await notifier.createCheckoutSession(packageId);

    if (url != null && context.mounted) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start checkout. Please try again.')),
      );
    }
  }

  Future<void> _openBillingPortal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, dynamic>>(
        ApiConstants.billingPortal,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      if (url != null && context.mounted) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open billing portal. Please try again.'),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Plan Option Card
// ---------------------------------------------------------------------------

class _PlanOptionCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool isCurrentPlan;
  final VoidCallback? onUpgrade;

  const _PlanOptionCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isCurrentPlan,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: isCurrentPlan
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Flexible(child: Text(feature)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isCurrentPlan)
              Chip(
                label: const Text('Current Plan'),
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            else if (onUpgrade != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onUpgrade,
                  child: Text('Upgrade to $name'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
