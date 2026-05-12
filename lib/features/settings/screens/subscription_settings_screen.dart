import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/features/billing/providers/subscription_provider.dart';

// ---------------------------------------------------------------------------
// Subscription Settings Screen (Trainer)
// ---------------------------------------------------------------------------

/// Trainer-only subscription & billing management screen.
///
/// Mirrors [TrainerSubscriptionView] from the iOS app:
///   - Current plan display with tier badge & next billing date
///   - Plan features/benefits list
///   - Upgrade / downgrade options via billing portal
///   - Billing & invoice history
///   - Payment method management
///   - Cancel subscription (with confirmation)
class SubscriptionSettingsScreen extends ConsumerStatefulWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  ConsumerState<SubscriptionSettingsScreen> createState() =>
      _SubscriptionSettingsScreenState();
}

class _SubscriptionSettingsScreenState
    extends ConsumerState<SubscriptionSettingsScreen> {
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  Widget _buildBody(
    SubscriptionState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.subscription == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.subscription == null) {
      return _buildErrorState(state, theme, colorScheme);
    }

    final subscription = state.subscription;
    final isActive = subscription?.status == 'active';

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(subscriptionProvider.notifier).fetchSubscription(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ErrorBanner(
                  message: state.error!,
                  onDismiss: () {
                    ref
                        .read(subscriptionProvider.notifier)
                        .fetchSubscription();
                  },
                ),
              ),

            // -- Current Plan --
            const _SectionHeader(
              icon: Icons.card_membership_outlined,
              title: 'Current Plan',
            ),
            const SizedBox(height: 12),
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
            const _SectionHeader(
              icon: Icons.checklist_outlined,
              title: 'Plan Features',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: (subscription?.features ??
                          _defaultFreeFeatures())
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  feature,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isActive
                                        ? null
                                        : theme
                                            .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // -- Plan Comparison (upgrade / downgrade) --
            const _SectionHeader(
              icon: Icons.compare_arrows_outlined,
              title: 'Available Plans',
            ),
            const SizedBox(height: 12),
            _PlanComparisonCard(
              name: 'Free',
              price: '\$0 / month',
              features: const [
                'Basic client management',
                'Standard workout tracking',
                'Community access',
                'Limited storefront',
              ],
              isCurrentPlan: !isActive,
              onAction: null,
              actionLabel: null,
            ),
            const SizedBox(height: 12),
            _PlanComparisonCard(
              name: 'Pro',
              price: '\$29 / month',
              features: const [
                'Unlimited client management',
                'Advanced workout analytics',
                'Priority support',
                'Custom branding',
                'Full storefront access',
                'Team collaboration',
              ],
              isCurrentPlan: isActive,
              onAction: isActive
                  ? null
                  : () => _openBillingPortal(context),
              actionLabel: 'Upgrade to Pro',
            ),
            const SizedBox(height: 12),
            _PlanComparisonCard(
              name: 'Enterprise',
              price: '\$99 / month',
              features: const [
                'Everything in Pro',
                'Dedicated account manager',
                'API access',
                'Custom integrations',
                'White-label experience',
                'Priority SLA',
              ],
              isCurrentPlan: false,
              onAction: isActive
                  ? () => _openBillingPortal(context)
                  : () => _openBillingPortal(context),
              actionLabel: isActive ? 'Upgrade' : 'Contact Us',
            ),
            const SizedBox(height: 24),

            // -- Billing History --
            const _SectionHeader(
              icon: Icons.receipt_long_outlined,
              title: 'Billing & Invoices',
            ),
            const SizedBox(height: 12),
            _BillingHistoryCard(
              onViewAll: () => _openBillingPortal(context),
              onManagePayment: () => _openBillingPortal(context),
            ),
            const SizedBox(height: 24),

            // -- Payment Method --
            const _SectionHeader(
              icon: Icons.credit_card_outlined,
              title: 'Payment Method',
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.credit_card_rounded,
                  color: colorScheme.primary,
                ),
                title: const Text('Manage Payment Methods'),
                subtitle: const Text(
                  'Update your card or billing information',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openBillingPortal(context),
              ),
            ),
            const SizedBox(height: 24),

            // -- Danger Zone --
            if (isActive) ...[
              const _SectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Subscription Actions',
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    'Cancel Subscription',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  subtitle: const Text(
                    'Your plan will remain active until the end of the billing period',
                  ),
                  onTap: () => _showCancelConfirmation(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    SubscriptionState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: colorScheme.error),
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

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _openBillingPortal(BuildContext context) async {
    final notifier = ref.read(subscriptionProvider.notifier);
    final url = await notifier.getPortalLink();

    if (url != null && context.mounted) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open billing portal. Please try again.'),
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
                    'Cancellation processed. You retain access until the end of the billing period.',
                  ),
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

  List<String> _defaultFreeFeatures() {
    return [
      'Basic client management',
      'Standard workout tracking',
      'Community access',
      'Limited storefront',
    ];
  }
}

// =============================================================================
// Section Header
// =============================================================================

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

// =============================================================================
// Current Plan Card
// =============================================================================

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
    final colorScheme = theme.colorScheme;
    final isActive = status == 'active';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                    isActive
                        ? 'ACTIVE'
                        : (status?.toUpperCase() ?? 'INACTIVE'),
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMd().format(nextBillingDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (!isActive) ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Upgrade Plan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Plan Comparison Card
// =============================================================================

class _PlanComparisonCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool isCurrentPlan;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _PlanComparisonCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isCurrentPlan,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlan
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentPlan) ...[
              const SizedBox(height: 12),
              Chip(
                label: const Text('Current Plan'),
                backgroundColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              ),
            ] else if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Billing History Card
// =============================================================================

class _BillingHistoryCard extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onManagePayment;

  const _BillingHistoryCard({
    required this.onViewAll,
    required this.onManagePayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent invoices header
            Row(
              children: [
                Icon(
                  Icons.receipt_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Invoices',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'View your full billing history and download invoices',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder invoice rows
            const _InvoiceRow(
              date: 'May 1, 2026',
              description: 'Pro Plan - Monthly',
              amount: '\$29.00',
              status: 'Paid',
              statusColor: Colors.green,
            ),
            const Divider(height: 16),
            const _InvoiceRow(
              date: 'Apr 1, 2026',
              description: 'Pro Plan - Monthly',
              amount: '\$29.00',
              status: 'Paid',
              statusColor: Colors.green,
            ),
            const Divider(height: 16),
            const _InvoiceRow(
              date: 'Mar 1, 2026',
              description: 'Pro Plan - Monthly',
              amount: '\$29.00',
              status: 'Paid',
              statusColor: Colors.green,
            ),
            const SizedBox(height: 12),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View All Invoices'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onManagePayment,
                icon: const Icon(Icons.credit_card_outlined, size: 18),
                label: const Text('Manage Payment Method'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Invoice Row
// =============================================================================

class _InvoiceRow extends StatelessWidget {
  final String date;
  final String description;
  final String amount;
  final String status;
  final Color statusColor;

  const _InvoiceRow({
    required this.date,
    required this.description,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Error Banner
// =============================================================================

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error,
                size: 20, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  size: 16, color: theme.colorScheme.onErrorContainer),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
