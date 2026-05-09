import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';

/// A Material Design card widget that displays a trainer search result.
///
/// Shows the trainer's avatar, name, rating, location, specialty chips,
/// and an optional distance badge.
class TrainerSearchCard extends StatelessWidget {
  const TrainerSearchCard({
    super.key,
    required this.trainer,
    required this.onTap,
  });

  final TrainerSearchResult trainer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundImage: trainer.avatarUrl != null && trainer.avatarUrl!.isNotEmpty
                    ? NetworkImage(trainer.avatarUrl!)
                    : null,
                child: trainer.avatarUrl == null || trainer.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trainer.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trainer.isConnected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.link,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating & review count
                    if (trainer.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trainer.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (trainer.reviewCount != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${trainer.reviewCount})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    // Location
                    if (trainer.location != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trainer.location!,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Specialty chips
                    if (trainer.specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: trainer.specialties
                              .take(3)
                              .map(
                                (s) => Chip(
                                  label: Text(
                                    s,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Distance badge
              if (trainer.distance != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    children: [
                      Icon(
                        Icons.near_me,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trainer.distance!.toStringAsFixed(1)} km',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
