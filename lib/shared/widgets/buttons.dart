import 'package:flutter/material.dart';

// =============================================================================
// PrimaryButton
// =============================================================================

/// A filled action button with blue background and white text.
///
/// Supports an optional leading icon, a loading spinner that replaces the label,
/// configurable width (defaults to full-width), and a disabled grey state.
///
/// {@tool dartpad}
/// ```dart
/// PrimaryButton(
///   label: 'Save Profile',
///   icon: Icons.save,
///   onPressed: _handleSave,
///   isLoading: isSaving,
/// )
/// ```
/// {@end-tool}
class PrimaryButton extends StatelessWidget {
  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. When `null` the button is disabled.
  final VoidCallback? onPressed;

  /// An optional icon rendered before the label.
  final IconData? icon;

  /// When `true` the label is replaced by a [CircularProgressIndicator] and
  /// taps are ignored. Defaults to `false`.
  final bool isLoading;

  /// The button width. When `null` the button expands to fill the available
  /// width. Defaults to `null`.
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _disabled ? Colors.grey[400] : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SecondaryButton
// =============================================================================

/// An outlined action button with transparent background, blue border, and blue
/// text.
///
/// {@tool dartpad}
/// ```dart
/// SecondaryButton(
///   label: 'Cancel',
///   onPressed: _handleCancel,
/// )
/// ```
/// {@end-tool}
class SecondaryButton extends StatelessWidget {
  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. When `null` the button is disabled.
  final VoidCallback? onPressed;

  /// An optional icon rendered before the label.
  final IconData? icon;

  /// The button width. When `null` the button expands to fill the available
  /// width. Defaults to `null`.
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
  });

  bool get _disabled => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final borderColor = _disabled ? Colors.grey[400]! : accentColor;
    final textColor = _disabled ? Colors.grey[400]! : accentColor;

    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PremiumButton
// =============================================================================

/// A gradient action button with blue-to-purple background for premium/pro
/// features.
///
/// Includes a subtle shadow and white bold text. When [isLoading] is `true` a
/// [CircularProgressIndicator] replaces the label.
///
/// {@tool dartpad}
/// ```dart
/// PremiumButton(
///   label: 'Upgrade to Premium',
///   onPressed: _handleUpgrade,
/// )
/// ```
/// {@end-tool}
class PremiumButton extends StatelessWidget {
  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. When `null` the button is disabled.
  final VoidCallback? onPressed;

  /// An optional icon rendered before the label.
  final IconData? icon;

  /// When `true` the label is replaced by a [CircularProgressIndicator] and
  /// taps are ignored. Defaults to `false`.
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  bool get _disabled => onPressed == null || isLoading;

  /// The gradient used for the active (non-disabled) button fill.
  static const LinearGradient _activeGradient = LinearGradient(
    colors: [Colors.blue, Colors.purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: _disabled ? 0 : 2,
        shadowColor: Colors.purple.withValues(alpha: 0.3),
        child: InkWell(
          onTap: _disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: _disabled ? null : _activeGradient,
              color: _disabled ? Colors.grey[400] : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _disabled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
