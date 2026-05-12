import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// Educational slides content
// =============================================================================

class _EducationalSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _EducationalSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

const _slides = [
  _EducationalSlide(
    icon: Icons.track_changes_rounded,
    title: 'Track Your Progress',
    description:
        'Log workouts, track measurements, and watch your improvement over time '
        'with beautiful charts and detailed analytics.',
    color: Color(0xFF6C63FF),
  ),
  _EducationalSlide(
    icon: Icons.smart_toy_rounded,
    title: 'Smart Workouts',
    description:
        'Get AI-powered workout recommendations tailored to your goals. '
        'Voice feedback guides you through every rep and set.',
    color: Color(0xFF00BFA5),
  ),
  _EducationalSlide(
    icon: Icons.chat_rounded,
    title: 'Stay Connected',
    description:
        'Message your trainer, book sessions, and get notified about schedule '
        'changes — all in one place.',
    color: Color(0xFFFF6B6B),
  ),
  _EducationalSlide(
    icon: Icons.flag_rounded,
    title: 'Set & Achieve Goals',
    description:
        'Define your fitness goals, build healthy habits, and celebrate milestones '
        'as you crush each target.',
    color: Color(0xFFFFB74D),
  ),
  _EducationalSlide(
    icon: Icons.explore_rounded,
    title: 'Ready to Begin?',
    description:
        'You\'re all set! Start your fitness journey and unlock your full potential '
        'with Ziro Fit.',
    color: Color(0xFF6C63FF),
  ),
];

// =============================================================================
// Screen
// =============================================================================

/// Post-onboarding educational flow shown once after initial setup.
/// Displays 5 slides introducing the app's key features.
class EducationalOnboardingScreen extends StatefulWidget {
  final String? role;

  const EducationalOnboardingScreen({super.key, this.role});

  @override
  State<EducationalOnboardingScreen> createState() =>
      _EducationalOnboardingScreenState();
}

class _EducationalOnboardingScreenState
    extends State<EducationalOnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.heavyImpact();
    final role = widget.role ?? 'client';
    if (role == 'trainer') {
      context.go('/trainer/dashboard');
    } else {
      context.go('/client/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (hidden on first slide)
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    const SizedBox(width: 48),

                  // Skip
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: _slides
                    .map((slide) => _buildSlide(slide, theme))
                    .toList(),
              ),
            ),

            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? _slides[_currentPage].color
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1
                        ? 'Next'
                        : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_EducationalSlide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 56,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: slide.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
