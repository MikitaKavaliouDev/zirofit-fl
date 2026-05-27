import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/shared/widgets/buttons.dart';

/// A card widget for displaying a membership/package purchase option.
///
/// Mirrors the iOS [MembershipCardView] with a gradient header (blue→purple
/// when [isRecommended]), a large session count, price display, optional
/// "BEST VALUE" badge, and a "Buy Now" action.
///
/// {@tool dartpad}
/// ```dart
/// MembershipCard(
///   name: 'Elite Monthly',
///   sessionCount: 24,
///   price: 299,
///   description: 'Unlimited access to all classes and facilities.',
///   isRecommended: true,
///   onPurchase: () => print('Purchased!'),
/// )
/// ```
/// {@end-tool}
class MembershipCard extends StatelessWidget {
  /// The name/title of the membership package.
  final String name;

  /// Number of sessions included in this package.
  final int sessionCount;

  /// Total price for this package in dollars.
  final double price;

  /// Optional description text shown below the package name.
  final String? description;

  /// Whether this package is highlighted as the recommended/best value option.
  ///
  /// When `true`:
  ///   - The header uses a blue→purple gradient (instead of solid blue).
  ///   - An orange "BEST VALUE" pill badge is shown overlapping the boundary.
  final bool isRecommended;

  /// Called when the user taps the "Buy Now" button.
  final VoidCallback onPurchase;

  const MembershipCard({
    super.key,
    required this.name,
    required this.sessionCount,
    required this.price,
    this.description,
    this.isRecommended = false,
    required this.onPurchase,
  });

  // ── Gradient definitions ────────────────────────────────────────────────

  static const LinearGradient _recommendedGradient = LinearGradient(
    colors: [Colors.blue, Colors.purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient _defaultGradient = LinearGradient(
    colors: [Color(0xFF0083FF), Color(0xFF0083FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _formatPrice(double value) {
    // Show whole number if no cents, otherwise 2 decimals.
    if (value == value.roundToDouble()) {
      return '\$${value.toInt()}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: context.themeColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradientHeader(
              sessionCount: sessionCount,
              price: price,
              isRecommended: isRecommended,
              formatPrice: _formatPrice,
            ),
            _Body(
              name: name,
              sessionCount: sessionCount,
              price: price,
              description: description,
              isRecommended: isRecommended,
              onPurchase: onPurchase,
              formatPrice: _formatPrice,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

/// The top gradient section containing session count, "SESSIONS" label, and
/// price. When [isRecommended] an orange "BEST VALUE" badge is positioned to
/// overlap the bottom edge.
class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.sessionCount,
    required this.price,
    required this.isRecommended,
    required this.formatPrice,
  });

  final int sessionCount;
  final double price;
  final bool isRecommended;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            20,
            32,
            20,
            isRecommended ? 28 : 24,
          ),
          decoration: BoxDecoration(
            gradient:
                isRecommended
                    ? MembershipCard._recommendedGradient
                    : MembershipCard._defaultGradient,
          ),
          child: Column(
            children: [
              Text(
                '$sessionCount',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const Text(
                'SESSIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatPrice(price),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // ── "BEST VALUE" badge ────────────────────────────────────────────
        if (isRecommended)
          const Positioned(
            bottom: -14,
            left: 0,
            right: 0,
            child: Center(
              child: _BestValueBadge(),
            ),
          ),
      ],
    );
  }
}

/// Orange pill-shaped "BEST VALUE" badge.
class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'BEST VALUE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// The white body section below the gradient header.
class _Body extends StatelessWidget {
  const _Body({
    required this.name,
    required this.sessionCount,
    required this.price,
    this.description,
    required this.isRecommended,
    required this.onPurchase,
    required this.formatPrice,
  });

  final String name;
  final int sessionCount;
  final double price;
  final String? description;
  final bool isRecommended;
  final VoidCallback onPurchase;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perSessionPrice =
        sessionCount > 0 ? price / sessionCount : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        isRecommended ? 28 : 20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Package name ────────────────────────────────────────────────
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Description ─────────────────────────────────────────────────
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // ── Stats row ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '$sessionCount Sessions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatPrice(perSessionPrice)}/session',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Buy Now button ──────────────────────────────────────────────
          PrimaryButton(
            label: 'Buy Now',
            onPressed: onPurchase,
          ),
        ],
      ),
    );
  }
}
