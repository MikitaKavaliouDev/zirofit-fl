import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';

/// A full multi-step onboarding wizard with 3 steps:
///   1. Role Selection (Trainer / Client)
///   2. Profile Setup (avatar, name, bio)
///   3. Physical Stats (height, weight, experience level)
///
/// Uses [OnboardingProvider] for state management and GoRouter for navigation
/// on successful completion.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  // -- Step 2 controllers --
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _step2FormKey = GlobalKey<FormState>();
  String? _avatarPath;

  // -- Step 3 controllers --
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();
  String _experienceLevel = 'Beginner';

  // -- Experience options --
  static const _experienceOptions = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    // Sync the initial page with the provider state (important when the
    // provider is pre-initialised, e.g. in tests).
    _pageController = PageController(
      initialPage: ref.read(onboardingProvider).currentStep,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Navigation
  // --------------------------------------------------------------------------

  void _goNext() {
    ref.read(onboardingProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    ref.read(onboardingProvider.notifier).previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int page) {
    final currentStep = ref.read(onboardingProvider).currentStep;
    if (page > currentStep) {
      ref.read(onboardingProvider.notifier).nextStep();
    } else if (page < currentStep) {
      ref.read(onboardingProvider.notifier).previousStep();
    }
  }

  // --------------------------------------------------------------------------
  // Step actions
  // --------------------------------------------------------------------------

  Future<void> _handleContinue() async {
    final currentStep = ref.read(onboardingProvider).currentStep;

    switch (currentStep) {
      case 0:
        _handleStep1Continue();
      case 1:
        _handleStep2Continue();
      case 2:
        await _handleStep3Submit();
    }
  }

  void _handleStep1Continue() {
    final role = ref.read(onboardingProvider).role;
    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue')),
      );
      return;
    }
    _goNext();
  }

  void _handleStep2Continue() {
    if (!_step2FormKey.currentState!.validate()) return;
    ref.read(onboardingProvider.notifier).setProfile(
          _nameController.text.trim(),
          _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          _avatarPath,
        );
    _goNext();
  }

  Future<void> _handleStep3Submit() async {
    if (!_step3FormKey.currentState!.validate()) return;

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    // Double-check: validators ensure these are non-null at this point.
    if (height == null || weight == null) return;

    ref.read(onboardingProvider.notifier).setStats(
          height,
          weight,
          _experienceLevel,
        );

    final onboardingNotifier = ref.read(onboardingProvider.notifier);

    try {
      await onboardingNotifier.submit();
      if (!mounted) return;

      final role = ref.read(onboardingProvider).role;
      if (role == 'trainer') {
        context.go('/trainer/dashboard');
      } else {
        context.go('/client/dashboard');
      }
    } catch (_) {
      // Error is already surfaced in the bottom-bar error banner via
      // provider state so no extra SnackBar needed.
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Step indicator dots + skip/back ---
            _buildHeader(onboardingState, colorScheme),

            // --- PageView with the 3 steps ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildRoleStep(onboardingState, theme, colorScheme),
                  _buildProfileStep(theme, colorScheme),
                  _buildStatsStep(theme, colorScheme),
                ],
              ),
            ),

            // --- Bottom navigation buttons ---
            _buildBottomBar(onboardingState, colorScheme),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  Widget _buildHeader(OnboardingState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final isActive = i == state.currentStep;
              final isPast = i < state.currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
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
          ),

          const Spacer(),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 1 – Role Selection
  // --------------------------------------------------------------------------

  Widget _buildRoleStep(
    OnboardingState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.fitness_center_rounded,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Ziro Fit',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself to get started',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Trainer card
          _RoleCard(
            icon: Icons.fitness_center_rounded,
            title: "I'm a Trainer",
            subtitle: 'Create workouts, manage clients, grow your business',
            isSelected: state.role == 'trainer',
            onTap: () => ref.read(onboardingProvider.notifier).setRole('trainer'),
          ),
          const SizedBox(height: 16),

          // Client card
          _RoleCard(
            icon: Icons.person_outline_rounded,
            title: "I'm a Client",
            subtitle: 'Follow programs, track progress, reach your goals',
            isSelected: state.role == 'client',
            onTap: () => ref.read(onboardingProvider.notifier).setRole('client'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 2 – Profile Setup
  // --------------------------------------------------------------------------

  Widget _buildProfileStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Set Up Your Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo and your name',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Avatar picker
          GestureDetector(
            onTap: () {
              // In a real app this would open image_picker (camera/gallery).
              // For now demos and tests treat the tap as a visual affordance.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera / gallery coming soon')),
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primaryContainer,
                  child: _avatarPath != null
                      ? ClipOval(
                          child: Image.asset(
                            _avatarPath!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: colorScheme.onPrimaryContainer,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Name field
          Form(
            key: _step2FormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio field (optional, max 150 chars)
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  validator: null, // optional
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 3 – Physical Stats
  // --------------------------------------------------------------------------

  Widget _buildStatsStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Your Physical Stats',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us personalize your experience',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          Form(
            key: _step3FormKey,
            child: Column(
              children: [
                // Height
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height_rounded),
                    hintText: 'e.g. 175',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your height';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid height in cm';
                    }
                    if (parsed > 300) {
                      return 'Height seems too high';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Weight
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_rounded),
                    hintText: 'e.g. 70',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your weight';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid weight in kg';
                    }
                    if (parsed > 500) {
                      return 'Weight seems too high';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Experience level dropdown
                DropdownButtonFormField<String>(
                  initialValue: _experienceLevel,
                  decoration: const InputDecoration(
                    labelText: 'Experience Level',
                    prefixIcon: Icon(Icons.trending_up_rounded),
                  ),
                  items: _experienceOptions.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _experienceLevel = value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom bar – Back / Continue buttons
  // --------------------------------------------------------------------------

  Widget _buildBottomBar(OnboardingState state, ColorScheme colorScheme) {
    final isLastStep = state.currentStep == 2;
    final buttonText = isLastStep ? 'Get Started' : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error banner
            if (state.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Continue / Get Started button
            ElevatedButton(
              onPressed: state.isLoading ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Role Card
// =============================================================================

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

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
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
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
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
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
