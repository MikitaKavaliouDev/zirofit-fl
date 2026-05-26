import 'package:flutter/material.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/shared/widgets/cached_async_image.dart';

/// A generic header widget matching iOS [ZiroHeader].
///
/// Features an optional leading slot, optional avatar (with image or initials
/// fallback), a bold title, and an optional trailing slot.
///
/// Generic parameters [Leading] and [Trailing] allow type-safe slot widgets:
/// ```dart
/// ZiroHeader<Icon, Icon>(
///   title: 'Dashboard',
///   leading: const Icon(Icons.arrow_back),
///   trailing: const Icon(Icons.settings),
/// )
/// ```
///
/// {@tool dartpad}
/// ```dart
/// ZiroHeader(
///   title: 'Dashboard',
///   showAvatar: true,
///   avatarUrl: 'https://example.com/avatar.jpg',
///   leading: Icon(Icons.arrow_back),
///   trailing: Icon(Icons.settings),
/// )
/// ```
/// {@end-tool}
class ZiroHeader<Leading extends Widget, Trailing extends Widget>
    extends StatelessWidget {
  /// The title text displayed in the header.
  final String title;

  /// Whether to show the avatar circle next to the title.
  final bool showAvatar;

  /// URL for the avatar image. When null or empty, shows initials fallback.
  final String? avatarUrl;

  /// Called when the avatar is tapped.
  final VoidCallback? onAvatarTap;

  /// Optional leading widget (e.g., back button, menu icon).
  final Leading? leading;

  /// Optional trailing widget (e.g., settings icon, action button).
  final Trailing? trailing;

  const ZiroHeader({
    super.key,
    required this.title,
    this.showAvatar = false,
    this.avatarUrl,
    this.onAvatarTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 4,
        bottom: 8,
      ),
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading slot
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],

          // Avatar
          if (showAvatar) ...[
            _buildAvatar(context),
            const SizedBox(width: 12),
          ],

          // Title — takes remaining space, ellipsis overflow
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: themeColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Trailing slot
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }

  /// Builds the avatar widget — network image or initials circle fallback.
  Widget _buildAvatar(BuildContext context) {
    final themeColors = context.themeColors;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    Widget avatarContent;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarContent = CachedAsyncImage(
        imageUrl: avatarUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorWidget: _buildInitialsCircle(themeColors, initial),
      );
    } else {
      avatarContent = _buildInitialsCircle(themeColors, initial);
    }

    final avatar = ClipOval(
      child: SizedBox(
        width: 32,
        height: 32,
        child: avatarContent,
      ),
    );

    if (onAvatarTap != null) {
      return GestureDetector(onTap: onAvatarTap, child: avatar);
    }
    return avatar;
  }

  /// A circular placeholder with the first letter of [title] as initials.
  Widget _buildInitialsCircle(ThemeColors themeColors, String initial) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: themeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
