import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';
import 'package:zirofit_fl/features/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:zirofit_fl/features/onboarding/widgets/onboarding_nav_buttons.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/welcome_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/language_selection_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/map_location_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/avatar_photo_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/physical_stats_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/experience_level_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/fitness_goals_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/trainer_finder_step.dart';
import 'package:zirofit_fl/features/onboarding/widgets/steps/permissions_step.dart';

// =============================================================================
// Onboarding Screen — 8-Step Wizard with PageView
// =============================================================================

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;

  // -- Celebration animation --
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _celebrationAnim = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Navigation
  // --------------------------------------------------------------------------

  void _goNext() {
    HapticFeedback.lightImpact();
    ref.read(onboardingProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    ref.read(onboardingProvider.notifier).previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int page) {
    final state = ref.read(onboardingProvider);
    if (page > state.currentStep) {
      ref.read(onboardingProvider.notifier).nextStep();
    } else if (page < state.currentStep) {
      ref.read(onboardingProvider.notifier).previousStep();
    }
  }

  // --------------------------------------------------------------------------
  // Validation
  // --------------------------------------------------------------------------

  bool _isNextEnabled() {
    final state = ref.read(onboardingProvider);
    switch (state.currentStep) {
      case 1: // Language Selection — always has default
        return true;
      case 2: // Map Location — optional
        return true;
      case 3: // Avatar Photo — optional
        return true;
      case 4: // Physical Stats — optional
        return true;
      case 5: // Experience Level — always has default
        return true;
      case 6: // Fitness Goals — at least 1 required
        return state.hasFitnessGoals;
      case 7: // Trainer Finder — optional
        return true;
      case 8: // Permissions — optional (can skip non-essential)
        return true;
      default:
        return true;
    }
  }

  // --------------------------------------------------------------------------
  // Handle Continue / Submit
  // --------------------------------------------------------------------------

  Future<void> _handleNext() async {
    final currentState = ref.read(onboardingProvider);
    final isLastStep = currentState.currentStep >= currentState.totalSteps - 1;

    if (isLastStep) {
      await _handleSubmit();
    } else {
      _goNext();
    }
  }

  Future<void> _handleSubmit() async {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    try {
      await onboardingNotifier.submit();
      if (!mounted) return;

      // Celebration animation
      HapticFeedback.heavyImpact();
      _celebrationController.forward();

      // Wait for animation, then navigate to educational onboarding
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      final role = ref.read(onboardingProvider).role;
      context.go('/onboarding/education', extra: role);
    } catch (_) {
      // Error surfaced in bottom bar via provider state
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final totalSteps = onboardingState.totalSteps;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // --- Header: Back + Progress + Dots ---
                _buildHeader(onboardingState, colorScheme, totalSteps),

                // --- Progress bar ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: OnboardingProgressIndicator(),
                ),

                const SizedBox(height: 8),

                // --- PageView with 8 steps ---
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const ClampingScrollPhysics(),
                    children: const [
                      WelcomeStep(),
                      LanguageSelectionStep(),
                      MapLocationStep(),
                      AvatarPhotoStep(),
                      PhysicalStatsStep(),
                      ExperienceLevelStep(),
                      FitnessGoalsStep(),
                      TrainerFinderStep(),
                      PermissionsStep(),
                    ],
                  ),
                ),

                // --- Bottom navigation buttons ---
                OnboardingNavButtons(
                  onBack: _goBack,
                  onNext: _handleNext,
                  isNextEnabled: _isNextEnabled(),
                ),
              ],
            ),
          ),
        ),

        // --- Celebration overlay ---
        if (_celebrationController.isAnimating)
          _buildCelebrationOverlay(colorScheme),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  Widget _buildHeader(
    OnboardingState state,
    ColorScheme colorScheme,
    int totalSteps,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Back arrow (hidden on step 0)
          if (state.currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _goBack,
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Step indicator dots
          StepDotsIndicator(
            totalSteps: totalSteps,
            currentStep: state.currentStep,
          ),

          const Spacer(),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Celebration Overlay
  // --------------------------------------------------------------------------

  Widget _buildCelebrationOverlay(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _celebrationAnim,
      builder: (context, child) {
        return Container(
          color: colorScheme.primary.withValues(alpha: 0.95 * _celebrationAnim.value),
          child: Center(
            child: Transform.scale(
              scale: _celebrationAnim.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'All Set!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You're ready to start your\nfitness journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
