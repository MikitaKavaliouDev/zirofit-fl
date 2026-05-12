import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A credit balance indicator matching iOS [CreditStatusWidget].
///
/// Displays a wallet icon alongside "X Credits" text, colored green when
/// the balance is positive and red when low or zero.
///
/// {@tool dartpad}
/// ```dart
/// CreditStatusWidget(
///   credits: 42,
///   lowCreditThreshold: 5,
/// )
/// ```
/// {@end-tool}
class CreditStatusWidget extends StatelessWidget {
  /// The current credit balance.
  final int credits;

  /// Credits at or below this threshold are considered "low".
  ///
  /// Defaults to 5.
  final int lowCreditThreshold;

  /// The size of the leading icon. Defaults to 18.0.
  final double iconSize;

  /// The icon used for the credit display.
  ///
  /// Defaults to [Icons.account_balance_wallet].
  final IconData icon;

  const CreditStatusWidget({
    super.key,
    required this.credits,
    this.lowCreditThreshold = 5,
    this.iconSize = 18,
    this.icon = Icons.account_balance_wallet,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final isLow = credits <= lowCreditThreshold;
    final color = isLow ? Colors.red : themeColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          '$credits Credits',
          style: TextStyle(
            fontSize: 14, // bodyMedium
            fontWeight: FontWeight.w600, // semibold
            color: color,
          ),
        ),
      ],
    );
  }
}
