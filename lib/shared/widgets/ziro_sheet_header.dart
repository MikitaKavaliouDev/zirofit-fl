import 'package:flutter/material.dart';
import 'package:zirofit_fl/shared/widgets/ziro_blur.dart';

/// A sheet header widget matching iOS [ZiroSheetHeader].
///
/// Displays a drag handle (capsule), centered title, optional Cancel and/or
/// Done buttons, and an optional trailing icon. The background uses an
/// ultra-thin material blur effect via [ZiroBlur].
///
/// {@tool dartpad}
/// ```dart
/// ZiroSheetHeader(
///   title: 'New Workout',
///   showCancel: true,
///   showDone: true,
///   onCancel: () => Navigator.of(context).pop(),
///   onDone: () => print('Done'),
/// )
/// ```
/// {@end-tool}
class ZiroSheetHeader extends StatelessWidget {
  /// The title centered in the header.
  final String title;

  /// Whether to show the Cancel button on the leading side.
  final bool showCancel;

  /// Whether to show the Done button on the trailing side.
  final bool showDone;

  /// Called when Cancel is tapped.
  final VoidCallback? onCancel;

  /// Called when Done is tapped.
  final VoidCallback? onDone;

  /// The text for the Cancel button. Defaults to 'Cancel'.
  final String leadingText;

  /// The text for the Done button. Defaults to 'Done'.
  final String trailingText;

  /// Optional trailing icon (e.g., filter, add, or more).
  final IconData? trailingIcon;

  /// Called when the trailing icon is tapped.
  final VoidCallback? onTrailingIconTap;

  const ZiroSheetHeader({
    super.key,
    required this.title,
    this.showCancel = false,
    this.showDone = false,
    this.onCancel,
    this.onDone,
    this.leadingText = 'Cancel',
    this.trailingText = 'Done',
    this.trailingIcon,
    this.onTrailingIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return ZiroBlur(
      blurStyle: ZiroBlurStyle.systemUltraThinMaterial,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(),

          // Title row with Cancel / Done buttons
          _buildTitleRow(),
        ],
      ),
    );
  }

  /// The drag handle capsule at the top of the sheet.
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  /// The title row with centered text and Cancel/Done/trailing-icon buttons.
  Widget _buildTitleRow() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered title
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Leading and trailing actions (positioned over the title)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Cancel button
                  if (showCancel)
                    GestureDetector(
                      onTap: onCancel,
                      child: Text(
                        leadingText,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Trailing icon
                  if (trailingIcon != null)
                    Padding(
                      padding: EdgeInsets.only(
                        right: showDone ? 12 : 0,
                      ),
                      child: GestureDetector(
                        onTap: onTrailingIconTap,
                        child: Icon(
                          trailingIcon,
                          size: 20,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                  // Done button (semibold to match iOS emphasis)
                  if (showDone)
                    GestureDetector(
                      onTap: onDone,
                      child: Text(
                        trailingText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
