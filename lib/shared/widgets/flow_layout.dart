import 'package:flutter/material.dart';

/// A layout widget that arranges its children in a horizontal flow,
/// wrapping to the next line when they overflow.
///
/// Uses Flutter's [Wrap] widget internally, matching the behavior of
/// SwiftUI's `LazyVGrid` with adaptive columns.
///
/// {@tool dartpad}
/// ```dart
/// FlowLayout(
///   spacing: 8,
///   runSpacing: 12,
///   children: [
///     Chip(label: Text('Tag 1')),
///     Chip(label: Text('Tag 2')),
///     Chip(label: Text('Tag 3')),
///   ],
/// )
/// ```
/// {@end-tool}
class FlowLayout extends StatelessWidget {
  /// The list of widgets to lay out in a flowing horizontal arrangement.
  final List<Widget> children;

  /// The spacing along the main axis (horizontal) between children.
  ///
  /// Defaults to 8.0.
  final double spacing;

  /// The spacing along the cross axis (vertical) between wrapped lines.
  ///
  /// Defaults to 8.0.
  final double runSpacing;

  /// Horizontal alignment of children within each run (line).
  ///
  /// Defaults to [WrapAlignment.start].
  final WrapAlignment alignment;

  /// Vertical alignment of runs (lines).
  ///
  /// Defaults to [WrapAlignment.start].
  final WrapAlignment runAlignment;

  /// How children within a run are aligned vertically.
  ///
  /// Defaults to [WrapCrossAlignment.start].
  final WrapCrossAlignment crossAxisAlignment;

  /// The direction along which the children flow.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis direction;

  /// The vertical text direction used to resolve alignment.
  final TextDirection? textDirection;

  /// The vertical direction used to stack runs.
  final VerticalDirection verticalDirection;

  /// Whether to constrain unidentified children to the run spacing.
  final Clip clipBehavior;

  const FlowLayout({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.direction = Axis.horizontal,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      direction: direction,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}
