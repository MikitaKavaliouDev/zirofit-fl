import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';

/// Step 5: Select experience level from 4 tiers.
class ExperienceLevelStep extends ConsumerWidget {
  const ExperienceLevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const levels = ExperienceLevel.values;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Header
            Icon(
              Icons.trending_up_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Experience Level',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'How would you describe your fitness level?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 4 Experience level cards
            ...levels.map(
              (level) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExperienceCard(
                  level: level,
                  isSelected: state.experienceLevel == level,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(onboardingProvider.notifier)
                        .setExperienceLevel(level);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final ExperienceLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconForLevel(ExperienceLevel l) {
    switch (l) {
      case ExperienceLevel.beginner:
        return Icons.fitness_center_rounded;
      case ExperienceLevel.intermediate:
        return Icons.show_chart_rounded;
      case ExperienceLevel.advanced:
        return Icons.rocket_launch_rounded;
      case ExperienceLevel.expert:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForLevel(level),
                size: 28,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
