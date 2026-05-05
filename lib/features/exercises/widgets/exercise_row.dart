import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

/// A single exercise row for selection lists.
///
/// Displays a thumbnail, search-highlighted name, muscle group subtitle,
/// an info button, and a selection indicator.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    this.searchQuery,
    this.isSelected = false,
    this.onTap,
    this.onInfoTap,
  });

  /// The exercise to display.
  final Exercise exercise;

  /// Optional search query for highlighting matches in the exercise name.
  final String? searchQuery;

  /// Whether this exercise is currently selected.
  final bool isSelected;

  /// Called when the row itself is tapped.
  final VoidCallback? onTap;

  /// Called when the info icon button is tapped.
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = exercise.imageUrl ?? exercise.videoUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Leading: 44x44 thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _ThumbnailContent(url: thumbnailUrl),
                ),
              ),
              const SizedBox(width: 12),
              // Center: name + muscle group
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        children: _buildNameSpans(theme),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise.muscleGroup != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        exercise.muscleGroup!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing: info button + selection icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: onInfoTap,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Exercise details',
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                    size: 24,
                    color: isSelected
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the name [TextSpan] list, optionally with search highlighting.
  List<TextSpan> _buildNameSpans(ThemeData theme) {
    final name = exercise.name;
    final query = searchQuery;

    if (query == null || query.isEmpty) {
      return [TextSpan(text: name)];
    }

    final spans = _highlightText(name, query, theme);
    return spans;
  }

  /// Highlights portions of [text] that match [query].
  ///
  /// 1. Tokenizes [query] by non-alphanumeric characters.
  /// 2. Finds all case-insensitive matching ranges in [text].
  /// 3. Merges overlapping ranges.
  /// 4. Returns spans with matched portions in bold + accent color.
  List<TextSpan> _highlightText(
    String text,
    String query,
    ThemeData theme,
  ) {
    // Tokenize query by non-alphanumeric characters
    final tokens = query
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return [TextSpan(text: text)];

    // Find all case-insensitive matching ranges
    final lowerText = text.toLowerCase();
    final ranges = <_Range>[];
    for (final token in tokens) {
      final lowerToken = token.toLowerCase();
      int start = 0;
      while (true) {
        final index = lowerText.indexOf(lowerToken, start);
        if (index == -1) break;
        ranges.add(_Range(index, index + token.length));
        start = index + 1;
      }
    }

    if (ranges.isEmpty) return [TextSpan(text: text)];

    // Sort and merge overlapping ranges
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Range>[];
    for (final range in ranges) {
      if (merged.isEmpty || merged.last.end < range.start) {
        merged.add(range);
      } else {
        merged.last.end =
            merged.last.end > range.end ? merged.last.end : range.end;
      }
    }

    // Build text spans
    final spans = <TextSpan>[];
    int current = 0;
    for (final range in merged) {
      if (current < range.start) {
        spans.add(TextSpan(text: text.substring(current, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
      );
      current = range.end;
    }
    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current)));
    }

    return spans;
  }
}

/// Internal widget for rendering the thumbnail with CachedNetworkImage + fallback.
class _ThumbnailContent extends StatelessWidget {
  const _ThumbnailContent({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) return _buildFallback(context);

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => _buildFallback(context),
      errorWidget: (_, _, _) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.fitness_center, size: 20),
    );
  }
}

/// Helper class for tracking text match ranges.
class _Range {
  final int start;
  int end;

  _Range(this.start, this.end);
}
