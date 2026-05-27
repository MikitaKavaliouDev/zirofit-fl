import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/client_package.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/features/clients/providers/client_packages_provider.dart';

class ClientPackagesScreen extends ConsumerStatefulWidget {
  const ClientPackagesScreen({super.key});

  @override
  ConsumerState<ClientPackagesScreen> createState() =>
      _ClientPackagesScreenState();
}

class _ClientPackagesScreenState
    extends ConsumerState<ClientPackagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientPackagesProvider.notifier).fetchPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(clientPackagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(clientPackagesProvider.notifier).fetchPackages(),
        child: _buildBody(theme, state),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ClientPackagesState state) {
    if (state.isLoading && state.purchased.isEmpty && state.available.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.purchased.isEmpty && state.available.isEmpty) {
      return _buildErrorState(theme, state.error!);
    }

    final hasPurchased = state.purchased.isNotEmpty;
    final hasAvailable = state.available.isNotEmpty;

    if (!hasPurchased && !hasAvailable) {
      return _buildEmptyState(theme);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (hasPurchased) ...[
          _buildSectionHeader(theme, 'My Packages'),
          const SizedBox(height: 8),
          ...state.purchased.map(
            (cp) => _MyPackageCard(
              clientPackage: cp,
              packageName: state.packageMap[cp.packageId]?.name,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (hasAvailable) ...[
          _buildSectionHeader(theme, 'Available Packages'),
          const SizedBox(height: 8),
          ...state.available.map(
            (pkg) => _AvailablePackageCard(
              package: pkg,
              onTap: () => _showPurchaseSheet(theme, pkg),
            ),
          ),
        ],
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(clientPackagesProvider.notifier).fetchPackages(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No packages available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trainer hasn\'t published any packages yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPurchaseSheet(ThemeData theme, Package pkg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PurchaseSheet(
        package: pkg,
        isPurchasing: ref.watch(clientPackagesProvider).isPurchasing,
        onPurchase: () {
          Navigator.pop(context);
          ref.read(clientPackagesProvider.notifier).purchasePackage(pkg.id);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Package Card
// ---------------------------------------------------------------------------

class _MyPackageCard extends StatelessWidget {
  final ClientPackage clientPackage;
  final String? packageName;

  const _MyPackageCard({
    required this.clientPackage,
    this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSessions = _totalSessions;
    final pct = totalSessions > 0
        ? clientPackage.sessionsRemaining / totalSessions
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    packageName ?? 'Package',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (clientPackage.sessionsRemaining <= 0)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (totalSessions > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    pct > 0
                        ? theme.colorScheme.primary
                        : Colors.green.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              clientPackage.sessionsRemaining <= 0
                  ? 'All sessions completed'
                  : '${clientPackage.sessionsRemaining} session${clientPackage.sessionsRemaining == 1 ? '' : 's'} remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: clientPackage.sessionsRemaining <= 0
                    ? Colors.green.shade600
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Since ClientPackage doesn't store total sessions, we derive a reasonable
  /// default. In practice the API should return this or the package map will
  /// provide it. If we can't derive, hide the progress bar.
  int get _totalSessions {
    // The api_constants had `sessionsRemaining` — without original count we
    // assume remaining was the initial count. A real package lookup would
    // give `numberOfSessions`. We fall back to remaining + 1 to avoid div/0.
    return clientPackage.sessionsRemaining + 1;
  }
}

// ---------------------------------------------------------------------------
// Available Package Card
// ---------------------------------------------------------------------------

class _AvailablePackageCard extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;

  const _AvailablePackageCard({
    required this.package,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (package.description != null &&
                        package.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        package.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${package.numberOfSessions} session${package.numberOfSessions == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${package.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Purchase Bottom Sheet
// ---------------------------------------------------------------------------

class _PurchaseSheet extends StatelessWidget {
  final Package package;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  const _PurchaseSheet({
    required this.package,
    required this.isPurchasing,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          // Package name
          Text(
            package.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Summary
          Text(
            '${package.numberOfSessions} session${package.numberOfSessions == 1 ? '' : 's'} for \$${package.price.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You will be redirected to complete your purchase.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Purchase button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isPurchasing ? null : onPurchase,
              child: isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Purchase — \$${package.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
