import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A swipe-to-delete widget that wraps [Dismissible] with a red delete
/// background, trash icon, and haptic feedback.
///
/// Matches the behavior of the iOS [SwipeView] component:
/// - Swipe left (endToStart) to reveal delete action
/// - Red background with trash icon
/// - [HapticFeedback.heavyImpact] on deletion
/// - Spring animation on dismiss
/// - Configurable [cornerRadius]
///
/// {@tool dartpad}
/// ```dart
/// SwipeView(
///   onDelete: () => print('Deleted'),
///   cornerRadius: 12,
///   child: Card(child: ListTile(title: Text('Item'))),
/// )
/// ```
/// {@end-tool}
class SwipeView extends StatelessWidget {
  /// The content widget to be swipeable.
  final Widget child;

  /// Called when the widget is swiped past the delete threshold.
  final VoidCallback onDelete;

  /// Corner radius applied to the dismissible container.
  ///
  /// Defaults to 0.
  final double cornerRadius;

  /// Whether the swipe-to-delete is enabled.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Optional confirmation dialog builder. If provided, the delete
  /// only proceeds if the dialog returns true.
  final Future<bool?> Function(DismissDirection direction)? confirmDismiss;

  const SwipeView({
    super.key,
    required this.child,
    required this.onDelete,
    this.cornerRadius = 0,
    this.enabled = true,
    this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('swipe_${onDelete.hashCode}'),
      direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onError,
          size: 28,
        ),
      ),
      confirmDismiss: confirmDismiss,
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        onDelete();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: child,
      ),
    );
  }
}

/// Extension on [Widget] to add swipe-to-delete functionality.
///
/// Usage:
/// ```dart
/// Card(child: Text('Swipe me'))
///   .swipeDelete(onDelete: () => print('Deleted'));
/// ```
extension SwipeDeleteExtension on Widget {
  /// Wraps this widget in a [SwipeView] for swipe-to-delete behavior.
  ///
  /// [onDelete] is called when the widget is dismissed.
  /// [cornerRadius] controls the border radius of the swipe container.
  /// [enabled] controls whether swipe is active.
  /// [confirmDismiss] provides optional confirmation dialog.
  Widget swipeDelete({
    required VoidCallback onDelete,
    double cornerRadius = 0,
    bool enabled = true,
    Future<bool?> Function(DismissDirection direction)? confirmDismiss,
  }) {
    return SwipeView(
      onDelete: onDelete,
      cornerRadius: cornerRadius,
      enabled: enabled,
      confirmDismiss: confirmDismiss,
      child: this,
    );
  }
}
