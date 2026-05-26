import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Pro Paywall Screen
// ---------------------------------------------------------------------------

/// A full-screen subscription upsell screen that mirrors the iOS
/// [ProPaywallView] behaviour. Displays feature comparison, monthly / annual
/// pricing toggle, a primary CTA, and legal footer links.
class ProPaywallScreen extends StatefulWidget {
  const ProPaywallScreen({super.key});

  @override
  State<ProPaywallScreen> createState() => _ProPaywallScreenState();
}

class _ProPaywallScreenState extends State<ProPaywallScreen> {
  bool _isAnnual = false;

  // ---------------------------------------------------------------------------
  // Feature data
  // ---------------------------------------------------------------------------

  static const _features = <_FeatureItem>[
    _FeatureItem(Icons.fitness_center, 'Basic workout tracking', true),
    _FeatureItem(Icons.people_outline, 'Basic client management', true),
    _FeatureItem(Icons.assignment, 'Unlimited workout plans', false),
    _FeatureItem(Icons.bar_chart, 'Advanced analytics', false),
    _FeatureItem(Icons.library_books, 'Custom exercise library', false),
    _FeatureItem(Icons.headset_mic, 'Priority support', false),
    _FeatureItem(Icons.do_not_disturb_alt, 'Remove ads', false),
    _FeatureItem(Icons.record_voice_over, 'Voice coaching', false),
    _FeatureItem(Icons.group, 'Team management', false),
    _FeatureItem(Icons.palette_outlined, 'Custom branding', false),
  ];

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(colorScheme, theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _buildFeatureComparison(colorScheme, theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _buildPricing(colorScheme, theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _buildCta(colorScheme, theme),
          ),
          const SizedBox(height: 24),
          _buildFooter(colorScheme, theme),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        children: [
          // Premium icon in a frosted-glass container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Unlock Premium Features',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get the most out of your fitness journey with Pro',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Compare plans and choose what\'s right for you',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeatureRow(feature: feature),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricing(ColorScheme colorScheme, ThemeData theme) {
    final priceText = _isAnnual ? '\$79.99 / year' : '\$9.99 / month';
    final perMonthText = _isAnnual ? '\$6.67 / month billed annually' : null;
    final showSaveBadge = _isAnnual;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Choose Your Plan',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // -- Monthly / Annual Toggle --
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_month),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Annual'),
                  icon: Icon(Icons.event),
                ),
              ],
              selected: {_isAnnual},
              onSelectionChanged: (Set<bool> selected) {
                setState(() => _isAnnual = selected.first);
              },
              style: SegmentedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // -- Price display --
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  priceText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                if (showSaveBadge) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Save 33%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (perMonthText != null) ...[
              const SizedBox(height: 4),
              Text(
                perMonthText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCta(ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isAnnual
                    ? 'Starting annual Pro subscription...'
                    : 'Starting monthly Pro subscription...',
              ),
            ),
          );
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
        ),
        child: const Text('Continue'),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, ThemeData theme) {
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          TextButton(
            onPressed: () => _showComingSoon(context, 'Terms of Service'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Terms of Service', style: linkStyle),
          ),
          Text(
            '|',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          TextButton(
            onPressed: () => _showComingSoon(context, 'Privacy Policy'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Privacy Policy', style: linkStyle),
          ),
          Text(
            '|',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          TextButton(
            onPressed: () => _showComingSoon(context, 'Restore Purchases'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Restore Purchases', style: linkStyle),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Item Model
// ---------------------------------------------------------------------------

class _FeatureItem {
  final IconData icon;
  final String name;
  final bool free;

  const _FeatureItem(this.icon, this.name, this.free);
}

// ---------------------------------------------------------------------------
// Feature Row
// ---------------------------------------------------------------------------

class _FeatureRow extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          feature.icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            feature.name,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        _TierBadge(free: feature.free),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tier Badge (FREE / PRO)
// ---------------------------------------------------------------------------

class _TierBadge extends StatelessWidget {
  final bool free;

  const _TierBadge({required this.free});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (free) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'FREE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'PRO',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
