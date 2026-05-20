import 'package:flutter/material.dart';

enum FinishOption { completeUnfinished, discardUnfinished }

class FinishWorkoutAlert {
  static Future<FinishOption?> show(BuildContext context) {
    return showDialog<FinishOption>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _FinishDialog(),
    );
  }
}

class _FinishDialog extends StatelessWidget {
  const _FinishDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎉 Emoji
            const Text(
              '🎉',
              style: TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Finish Workout?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Description
            const Text(
              'There are valid sets in this workout that have not been marked as complete.\nInvalid or empty sets will be removed.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Button 1: Complete Unfinished Sets
            _FinishDialogButton(
              label: 'Complete Unfinished Sets',
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              onTap: () =>
                  Navigator.of(context).pop(FinishOption.completeUnfinished),
            ),
            const SizedBox(height: 12),
            // Button 2: Discard Unfinished Sets
            _FinishDialogButton(
              label: 'Discard Unfinished Sets',
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
              onTap: () =>
                  Navigator.of(context).pop(FinishOption.discardUnfinished),
            ),
            const SizedBox(height: 12),
            // Button 3: Cancel
            _FinishDialogButton(
              label: 'Cancel',
              backgroundColor: const Color(0xFFF1F1F1),
              foregroundColor: Colors.black,
              onTap: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishDialogButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _FinishDialogButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
