import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/profile.dart';

/// Featured trainers section - horizontal scroll of trainer cards.
///
/// Navigates to [PublicTrainerProfileScreen] on tap.
///
/// Usage:
/// ```dart
/// FeaturedTrainersSection(
///   trainers: state.featuredTrainers,
///   onTrainerTap: (trainer) => Navigator.push(...),
/// )
/// ```
class FeaturedTrainersSection extends StatelessWidget {
  final List<Profile> trainers;
  final void Function(Profile trainer) onTrainerTap;

  const FeaturedTrainersSection({
    super.key,
    required this.trainers,
    required this.onTrainerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trainers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Featured Trainers',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trainers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final trainer = trainers[index];
              return _FeaturedTrainerCard(
                trainer: trainer,
                onTap: () => onTrainerTap(trainer),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedTrainerCard extends StatelessWidget {
  final Profile trainer;
  final VoidCallback onTap;

  const _FeaturedTrainerCard({
    required this.trainer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: trainer.profilePhotoPath != null && trainer.profilePhotoPath!.isNotEmpty
                  ? NetworkImage(trainer.profilePhotoPath!)
                  : null,
              child: trainer.profilePhotoPath == null || trainer.profilePhotoPath!.isEmpty
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              trainer.aboutMe ?? 'Trainer',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (trainer.specialties.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                trainer.specialties.first,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (trainer.averageRating != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    trainer.averageRating!.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}