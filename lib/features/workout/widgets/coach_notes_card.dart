import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

// =============================================================================
// CoachNotesCard
// =============================================================================

/// Displays coach notes with an optional video reference for trainer-led
/// workout sessions.
///
/// Matches iOS [CoachNoteCard] design (WorkoutExerciseCard.swift:956) with:
/// - Blue quote icon + trainer name header
/// - Italic note body with decorative quote accent
/// - Optional video URL section with play button and "Watch Video" CTA
///
/// Can be used inline or inside a bottom sheet (max height ~350).
///
/// {@tool dartpad}
/// ```dart
/// CoachNotesCard(
///   note: 'Focus on tempo — 3s eccentric, explosive concentric.',
///   videoUrl: 'https://youtube.com/watch?v=abc123',
///   trainerName: 'Coach Mike',
///   onWatchVideo: () => print('Watch video'),
/// )
/// ```
/// {@end-tool}
class CoachNotesCard extends StatelessWidget {
  /// The coach's instruction or note text.
  final String note;

  /// Optional URL to an instructional demonstration video.
  final String? videoUrl;

  /// Display name of the trainer/coach providing the notes.
  final String trainerName;

  /// Called when the user taps the "Watch Video" button.
  final VoidCallback? onWatchVideo;

  const CoachNotesCard({
    super.key,
    required this.note,
    this.videoUrl,
    this.trainerName = 'Coach',
    this.onWatchVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 350),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header: quote icon + trainer name ----
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: Colors.blue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  "$trainerName's Notes",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ---- Divider ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),

          // ---- Scrollable content ----
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note text with quote accent
                  _NoteBody(note: note, theme: theme, colors: colors),

                  // Video section
                  if (hasVideo) ...[
                    const SizedBox(height: 24),
                    _VideoSection(
                      videoUrl: videoUrl!,
                      onWatchVideo: onWatchVideo,
                      theme: theme,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Styled note body with a decorative blue quote marker and italic text.
class _NoteBody extends StatelessWidget {
  final String note;
  final ThemeData theme;
  final ThemeColors colors;

  const _NoteBody({
    required this.note,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative quote bar
          Container(
            width: 3,
            margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Note text
          Expanded(
            child: Text(
              note,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: colors.textPrimary.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the video URL and a "Watch Video" action button.
class _VideoSection extends StatelessWidget {
  final String videoUrl;
  final VoidCallback? onWatchVideo;
  final ThemeData theme;
  final ThemeColors colors;

  const _VideoSection({
    required this.videoUrl,
    required this.onWatchVideo,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // URL display with play icon
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: Colors.blue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  videoUrl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Watch Video button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onWatchVideo,
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Watch Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
