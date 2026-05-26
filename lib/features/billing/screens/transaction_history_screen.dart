import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Transaction / Purchase History Screen
// ---------------------------------------------------------------------------

/// Displays a paginated list of financial transactions (purchases, payments,
/// refunds). Trainer view shows "Transaction History"; client view shows
/// "Purchase History". Reuses [RevenueTransaction] from [billingProvider].
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(billingProvider.notifier).fetchRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final isClient = location.startsWith('/client');
    final title = isClient ? 'Purchase History' : 'Transaction History';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(billingState, theme),
    );
  }

  Widget _buildBody(BillingState state, ThemeData theme) {
    // --- Loading (first load) ---
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- Error (no cached data) ---
    if (state.error != null && state.transactions.isEmpty) {
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
                    ref.read(billingProvider.notifier).fetchRevenue(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // --- Empty state ---
    if (state.transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(billingProvider.notifier).fetchRevenue(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: const _EmptyTransactionState(),
            ),
          ],
        ),
      );
    }

    // --- Transaction list ---
    return RefreshIndicator(
      onRefresh: () => ref.read(billingProvider.notifier).fetchRevenue(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.transactions.length,
        itemBuilder: (context, index) {
          final txn = state.transactions[index];
          return _TransactionCard(transaction: txn);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Card
// ---------------------------------------------------------------------------

class _TransactionCard extends StatelessWidget {
  final RevenueTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = transaction.amount < 0 ||
        transaction.type == 'fee' ||
        transaction.type == 'refund';
    final absAmount = transaction.amount.abs();

    // Status badge color
    Color statusColor;
    switch (transaction.status.toLowerCase()) {
      case 'completed':
      case 'succeeded':
        statusColor = Colors.green;
        break;
      case 'pending':
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Top row: icon + title + amount --
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isNegative
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isNegative ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    transaction.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${isNegative ? '-' : '+'}\$${absAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // -- Bottom row: date + status badge --
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  transaction.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyTransactionState extends StatelessWidget {
  const _EmptyTransactionState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final isClient = location.startsWith('/client');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isClient ? 'No purchases yet' : 'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClient
                ? 'Your purchases from your trainer will appear here'
                : 'Revenue from your services and packages will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
