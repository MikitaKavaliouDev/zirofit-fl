import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';

/// iOS-style capsule progress bar with "Step X of 8" label above.
class OnboardingProgressIndicator extends ConsumerWidget {
  const OnboardingProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final total = state.totalSteps;
    final current = state.currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Step X of 8" label
        Text(
          'Step ${current + 1} of $total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        // Capsule progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (current + 1) / total,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// Dot-based step indicator used inside the header row.
class StepDotsIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepDotsIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isPast = i < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? colorScheme.primary
                : isPast
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}
