import 'package:flutter/material.dart';

import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/shared/widgets/cached_async_image.dart';

/// A card displaying a linked trainer's info, matching iOS [LinkedTrainerCard].
///
/// Shows the trainer's avatar (48px), name, specialty, and an optional
/// online status indicator. Tapping the card triggers [onTap].
///
/// {@tool dartpad}
/// ```dart
/// LinkedTrainerCard(
///   name: 'Sarah Johnson',
///   specialty: 'Strength & Conditioning',
///   avatarUrl: 'https://example.com/avatar.jpg',
///   isOnline: true,
///   onTap: () => print('Trainer tapped'),
/// )
/// ```
/// {@end-tool}
class LinkedTrainerCard extends StatelessWidget {
  /// The trainer's display name.
  final String name;

  /// The trainer's specialty or tagline.
  final String specialty;

  /// Optional URL for the trainer's avatar image.
  ///
  /// When null or empty, the avatar shows the initials of [name].
  final String? avatarUrl;

  /// Whether the trainer is currently online.
  ///
  /// When `true`, shows a green online indicator dot.
  final bool isOnline;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  const LinkedTrainerCard({
    super.key,
    required this.name,
    required this.specialty,
    this.avatarUrl,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar — 48px circle with image or initials fallback
              _buildAvatar(context),
              const SizedBox(width: 12),

              // Name and specialty
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status indicator
              if (isOnline)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a 48px circular avatar with network image or initials fallback.
  Widget _buildAvatar(BuildContext context) {
    final themeColors = context.themeColors;
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CachedAsyncImage(
            imageUrl: avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: _buildInitialsCircle(context, themeColors, initial),
            placeholder: _buildInitialsCircle(context, themeColors, initial),
          ),
        ),
      );
    }

    return _buildInitialsCircle(context, themeColors, initial);
  }

  /// A 48px circular placeholder with the first letter of [name].
  Widget _buildInitialsCircle(
    BuildContext context,
    ThemeColors themeColors,
    String initial,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
