import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/billing/providers/billing_provider.dart';

// ---------------------------------------------------------------------------
// Revenue Screen
// ---------------------------------------------------------------------------

/// Displays revenue overview with earnings history, balance, and recent
/// transactions.
class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(billingProvider.notifier).fetchRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(BillingState state, ThemeData theme) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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

    return RefreshIndicator(
      onRefresh: () => ref.read(billingProvider.notifier).fetchRevenue(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Available Balance Card --
          _BalanceCard(
            availableForPayout: state.availableForPayout,
            totalEarned: state.totalEarned,
          ),
          const SizedBox(height: 20),

          // -- Stats Grid --
          _StatsGrid(
            totalEarned: state.totalEarned,
            lastPayout: state.lastPayout,
            monthlyGrowth: state.monthlyGrowth,
          ),
          const SizedBox(height: 20),

          // -- Earnings Chart --
          _EarningsChart(monthlyGrowth: state.monthlyGrowth),
          const SizedBox(height: 20),

          // -- Recent Transactions --
          Text(
            'Recent Transactions',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (state.transactions.isEmpty)
            _EmptyRevenueState()
          else
            ...state.transactions.map(
              (txn) => _TransactionCard(transaction: txn),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance Card
// ---------------------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  final double availableForPayout;
  final double totalEarned;

  const _BalanceCard({
    required this.availableForPayout,
    required this.totalEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Available for Payout',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${availableForPayout.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawals are processed via Stripe.'),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Withdraw Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final double totalEarned;
  final double lastPayout;
  final double monthlyGrowth;

  const _StatsGrid({
    required this.totalEarned,
    required this.lastPayout,
    required this.monthlyGrowth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Lifetime',
            value: '\$${totalEarned.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Last Payout',
            value: '\$${lastPayout.toStringAsFixed(2)}',
            icon: Icons.arrow_downward,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Growth',
            value: '${monthlyGrowth.toStringAsFixed(1)}%',
            icon: Icons.show_chart,
            color: monthlyGrowth >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Earnings Chart (simple bar chart without external deps)
// ---------------------------------------------------------------------------

class _EarningsChart extends StatelessWidget {
  final double monthlyGrowth;

  const _EarningsChart({required this.monthlyGrowth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample weekly data points for the chart
    final data = [0.4, 0.65, 0.5, 0.8, 0.7, 0.9, 1.0];
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Earnings History',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${monthlyGrowth.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarChartPainter(data: data, barColor: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: labels
                  .map(
                    (l) => Text(
                      l,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;

  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (data.length * 1.8);
    final spacing = barWidth * 0.8;
    final startX = spacing / 2;

    for (var i = 0; i < data.length; i++) {
      final barHeight = data[i] * size.height * 0.85;
      final x = startX + i * (barWidth + spacing);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..color = i == data.length - 1
            ? barColor
            : barColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      data != oldDelegate.data;
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
    final isNegative = transaction.amount < 0 || transaction.type == 'fee';
    final absAmount = transaction.amount.abs();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                isNegative ? Icons.remove : Icons.add,
                color: isNegative ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.date}  \u2022  ${transaction.status}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isNegative ? '-' : '+'}\$${absAmount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNegative ? Colors.red : Colors.green,
              ),
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

class _EmptyRevenueState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Revenue from your services and packages will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
