import 'package:flutter/material.dart';

enum FinishOption { completeUnfinished, discardUnfinished }

class FinishWorkoutAlert {
  static Future<FinishOption?> show(BuildContext context) {
    return showDialog<FinishOption>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _FinishDialog(),
    );
  }
}

class _FinishDialog extends StatefulWidget {
  const _FinishDialog();

  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji at top
            const Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Finish Workout?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Options
            _buildOptionTile(
              context: context,
              icon: Icons.check_circle_outline,
              iconColor: Colors.orange,
              label: 'Complete Unfinished Sets',
              subtitle: 'Mark all valid sets as done',
              onTap: () => Navigator.of(context).pop(FinishOption.completeUnfinished),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context: context,
              icon: Icons.delete_outline,
              iconColor: Colors.red,
              label: 'Discard Unfinished Sets',
              subtitle: 'Remove all incomplete sets',
              onTap: () => Navigator.of(context).pop(FinishOption.discardUnfinished),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context: context,
              icon: Icons.close,
              iconColor: Colors.grey,
              label: 'Cancel',
              subtitle: 'Return to workout',
              onTap: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}