import 'package:flutter/material.dart';

// =============================================================================
// TagView
// =============================================================================

/// A colored tag pill matching iOS [TagView].
///
/// Displays a short text label with a tinted background and rounded corners.
/// Useful for status indicators, difficulty levels, categories, etc.
///
/// {@tool dartpad}
/// ```dart
/// TagView(text: 'Beginner', color: Colors.green)
/// ```
/// {@end-tool}
class TagView extends StatelessWidget {
  /// The text displayed inside the tag.
  final String text;

  /// The color used for the text and the tinted background.
  final Color color;

  const TagView({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11, // caption2 ≈ 11pt
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// TabButton
// =============================================================================

/// A segmented-control-style tab button matching iOS [TabButton].
///
/// Displays a title with a 2px underline indicator below the selected tab.
///
/// {@tool dartpad}
/// ```dart
/// TabButton(
///   title: 'Active',
///   isSelected: true,
///   action: () => print('Active tapped'),
/// )
/// ```
/// {@end-tool}
class TabButton extends StatelessWidget {
  /// The title text of the tab.
  final String title;

  /// Whether this tab is currently selected (underline is visible).
  final bool isSelected;

  /// Called when the tab is tapped.
  final VoidCallback action;

  const TabButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15, // subheadline ≈ 15pt
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SelectedUnderline(isSelected: isSelected),
        ],
      ),
    );
  }
}

/// A 2px underline that fills the column width when [isSelected] is true.
///
/// Extracted as a separate widget to use [double.infinity] width correctly
/// within the [Column] layout constraints.
class SelectedUnderline extends StatelessWidget {
  final bool isSelected;

  const SelectedUnderline({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: double.infinity,
      color: isSelected ? Colors.blue : Colors.transparent,
    );
  }
}
