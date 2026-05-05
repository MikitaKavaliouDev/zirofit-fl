import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Prompt types
// ---------------------------------------------------------------------------

/// The type of dashboard prompt determines icon and pastel colour.
enum DashboardPromptType {
  /// A new client has been assigned / joined.
  newClient,

  /// A client's check-in is overdue.
  overdueCheckin,

  /// An upcoming session needs attention.
  upcomingSession,
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Data needed to render a single dashboard prompt.
class DashboardPrompt {
  /// Unique identifier used for dismissal tracking in SharedPreferences.
  final String id;

  final DashboardPromptType type;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const DashboardPrompt({
    required this.id,
    required this.type,
    required this.title,
    required this.actionLabel,
    this.onAction,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A dismissible prompt banner that appears on the trainer dashboard.
///
/// Each prompt has a unique [id] used to persist dismissal state via
/// `SharedPreferences` so the same prompt is not shown twice.
///
/// Styling follows the app's design system:
///   - Border radius matches `CardTheme` (12)
///   - Spacing uses the 8‑px grid convention seen across the UI
///   - Colours are semantic pastels tied to [DashboardPromptType]
class DashboardPromptCard extends StatefulWidget {
  final DashboardPrompt prompt;

  const DashboardPromptCard({super.key, required this.prompt});

  @override
  State<DashboardPromptCard> createState() => _DashboardPromptCardState();
}

class _DashboardPromptCardState extends State<DashboardPromptCard> {
  bool _dismissed = false;

  static const String _prefsKeyPrefix = 'dismissed_prompt_';

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('$_prefsKeyPrefix${widget.prompt.id}') ?? false;
    if (mounted && dismissed != _dismissed) {
      setState(() => _dismissed = dismissed);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsKeyPrefix${widget.prompt.id}', true);
    if (mounted) {
      setState(() => _dismissed = true);
    }
  }

  // ---- Type-based helpers ------------------------------------------------

  IconData get _icon {
    switch (widget.prompt.type) {
      case DashboardPromptType.newClient:
        return Icons.person_add_outlined;
      case DashboardPromptType.overdueCheckin:
        return Icons.checklist_rtl;
      case DashboardPromptType.upcomingSession:
        return Icons.schedule_outlined;
    }
  }

  Color get _pastelBackground {
    switch (widget.prompt.type) {
      case DashboardPromptType.newClient:
        return const Color(0xFFE8F5E9); // green pastel
      case DashboardPromptType.overdueCheckin:
        return const Color(0xFFFFF3E0); // orange pastel
      case DashboardPromptType.upcomingSession:
        return const Color(0xFFE3F2FD); // blue pastel
    }
  }

  Color get _accentColor {
    switch (widget.prompt.type) {
      case DashboardPromptType.newClient:
        return const Color(0xFF2E7D32);
      case DashboardPromptType.overdueCheckin:
        return const Color(0xFFE65100);
      case DashboardPromptType.upcomingSession:
        return const Color(0xFF1565C0);
    }
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _pastelBackground,
        borderRadius: BorderRadius.circular(12), // matches CardTheme
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title + action button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.prompt.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () {
                          widget.prompt.onAction?.call();
                          _dismiss();
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 12),
                        label: Text(
                          widget.prompt.actionLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: _accentColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dismiss (X) button
              IconButton(
                onPressed: _dismiss,
                icon: Icon(Icons.close, size: 18, color: _accentColor.withValues(alpha: 0.6)),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Static helpers for checking / resetting dismissal state
// ---------------------------------------------------------------------------

/// Utility methods for managing dashboard prompt dismissal via SharedPreferences.
class DashboardPromptDismissal {
  DashboardPromptDismissal._();

  static const String _prefsKeyPrefix = 'dismissed_prompt_';

  /// Returns `true` if the prompt with [id] has been dismissed.
  static Future<bool> isDismissed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsKeyPrefix$id') ?? false;
  }

  /// Resets the dismissed state for a single prompt (useful for testing).
  static Future<void> resetDismissed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix$id');
  }

  /// Resets *all* dismissed prompts.
  static Future<void> resetAllDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
