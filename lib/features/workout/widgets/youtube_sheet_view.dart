import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';

/// A modal bottom sheet that displays a YouTube video URL and provides an
/// "Open in Browser" action.
///
/// Mirrors iOS [YouTubeSheetView] which uses SFSafariViewController to open
/// the video externally.
class YouTubeSheetView extends StatelessWidget {
  final String videoUrl;

  const YouTubeSheetView({super.key, required this.videoUrl});

  /// Shows the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, String videoUrl) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => YouTubeSheetView(videoUrl: videoUrl),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          // Header row: title + close button
          Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Coach Video',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Video URL display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    videoUrl,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Open in Browser button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 20),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
