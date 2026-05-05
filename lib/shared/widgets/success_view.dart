import 'dart:async';

import 'package:flutter/material.dart';

/// A full-screen success animation / page shown after successful operations.
///
/// Displays a large green checkmark icon with a subtle scale animation,
/// a title, an optional message, and an optional action button.
/// Auto-dismisses after 2 seconds unless the user taps the dismiss area
/// or the action button first.
class SuccessView extends StatefulWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const SuccessView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Auto-dismiss after 2 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Optional message
                if (widget.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.message!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Optional action button
                if (widget.actionLabel != null) ...[
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      widget.onAction?.call();
                      widget.onDismiss?.call();
                    },
                    child: Text(widget.actionLabel!),
                  ),
                ],

                // Manual dismiss hint
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
