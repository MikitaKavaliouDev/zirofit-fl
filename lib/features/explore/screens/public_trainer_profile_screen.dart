import 'package:flutter/material.dart';
import 'package:zirofit_fl/data/models/profile.dart';

class PublicTrainerProfileScreen extends StatelessWidget {
  final Profile trainer;

  const PublicTrainerProfileScreen({super.key, required this.trainer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(trainer.aboutMe ?? 'Trainer Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: trainer.profilePhotoPath != null
                        ? NetworkImage(trainer.profilePhotoPath!)
                        : null,
                    child: trainer.profilePhotoPath == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    trainer.aboutMe ?? 'Trainer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (trainer.location != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          trainer.location!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  if (trainer.averageRating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 20, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          trainer.averageRating!.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Specialties
            if (trainer.specialties.isNotEmpty) ...[
              Text(
                'Specialties',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: trainer.specialties.map((specialty) {
                  return Chip(
                    label: Text(specialty),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // About
            if (trainer.aboutMe != null &&
                trainer.aboutMe!.isNotEmpty) ...[
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainer.aboutMe!,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Certifications
            if (trainer.certifications != null &&
                trainer.certifications!.isNotEmpty) ...[
              Text(
                'Certifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainer.certifications!,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Philosophy
            if (trainer.philosophy != null &&
                trainer.philosophy!.isNotEmpty) ...[
              Text(
                'Philosophy',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainer.philosophy!,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Methodology
            if (trainer.methodology != null &&
                trainer.methodology!.isNotEmpty) ...[
              Text(
                'Methodology',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainer.methodology!,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Price info
            if (trainer.minServicePrice != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'From ${trainer.minServicePrice!.toStringAsFixed(2)} ${trainer.businessCurrency}',
                    style: theme.textTheme.titleMedium?.copyWith(
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
