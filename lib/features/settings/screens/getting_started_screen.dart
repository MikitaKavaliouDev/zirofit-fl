import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Guide Step Data
// ---------------------------------------------------------------------------

class _GuideStep {
  final int number;
  final IconData icon;
  final String title;
  final String brief;
  final List<String> details;
  final String? tip;

  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.brief,
    required this.details,
    this.tip,
  });
}

// ---------------------------------------------------------------------------
// Steps Content — Trainer & Client
// ---------------------------------------------------------------------------

const _trainerSteps = [
  _GuideStep(
    number: 1,
    icon: Icons.person_outline,
    title: 'Set Up Your Trainer Profile',
    brief:
        'Create a compelling trainer profile that helps clients find and '
        'trust you.',
    details: [
      'Upload a professional profile photo',
      'Write your bio — share your story and training philosophy',
      'Add certifications, qualifications, and methodology',
      'Set your work locations so clients know where you train',
      'Configure your physical stats (displayed on your profile)',
    ],
    tip:
        'Profiles with a photo and detailed bio receive 3x more client '
        'connection requests.',
  ),
  _GuideStep(
    number: 2,
    icon: Icons.miscellaneous_services_outlined,
    title: 'Configure Your Services & Pricing',
    brief:
        'Define what you offer and how much it costs so clients can '
        'choose the right package.',
    details: [
      'Create training services (1-on-1, small group, online coaching)',
      'Set up pricing packages with different tiers and durations',
      'Configure your availability and session scheduling preferences',
      'Set default check-in day, time, and weight unit',
      'Add any promotional or introductory offers',
    ],
    tip:
        'Offering 2-3 clear package tiers makes it easier for clients to '
        'choose the one that fits their needs.',
  ),
  _GuideStep(
    number: 3,
    icon: Icons.group_outlined,
    title: 'Invite & Manage Clients',
    brief:
        'Build your client community by inviting clients and organizing '
        'their experience.',
    details: [
      'Send client invitations through the app or share your trainer code',
      'Organize clients with custom notes and tags',
      'Set up assessment templates for initial evaluations',
      'Establish check-in routines to keep clients accountable',
      'Use the client list to quickly access individual progress and plans',
    ],
    tip:
        'Schedule the first check-in within 48 hours of a client connecting'
        ' to build momentum from day one.',
  ),
  _GuideStep(
    number: 4,
    icon: Icons.fitness_center_outlined,
    title: 'Create Workout Programs',
    brief:
        'Design professional training programs and templates for your '
        'clients.',
    details: [
      'Build reusable workout templates with exercises, sets, and reps',
      'Create full training programs that span multiple weeks',
      'Assign programs to individual clients or groups',
      'Track session completion and exercise performance',
      'Adjust programs on the fly based on client feedback and results',
    ],
    tip:
        'Start with 3-5 foundational templates you can customize per '
        'client rather than building from scratch every time.',
  ),
  _GuideStep(
    number: 5,
    icon: Icons.insights_outlined,
    title: 'Track Client Progress',
    brief:
        'Use data-driven insights to monitor results and keep clients '
        'motivated.',
    details: [
      'Review client check-ins and respond with feedback',
      'Track body measurements and transformation photos over time',
      'Monitor workout completion rates and performance trends',
      'Use progress analytics to identify what\'s working',
      'Celebrate milestones — personal records, consistency streaks, goals hit',
    ],
    tip:
        'Weekly progress reviews with your clients lead to 40% higher '
        'retention rates.',
  ),
];

const _clientSteps = [
  _GuideStep(
    number: 1,
    icon: Icons.person_pin_outlined,
    title: 'Complete Your Profile',
    brief:
        'Set up your profile so your trainer can personalize your '
        'fitness journey.',
    details: [
      'Add a profile photo so your trainer can recognize you',
      'Enter your physical stats (height, weight) for accurate tracking',
      'Set your fitness goals — what do you want to achieve?',
      'Let your trainer know about any injuries or limitations',
      'Review your account details and preferences',
    ],
    tip:
        'Being honest about your current fitness level helps your trainer '
        'design a program that\'s challenging but safe.',
  ),
  _GuideStep(
    number: 2,
    icon: Icons.link_outlined,
    title: 'Connect With Your Trainer',
    brief:
        'Link to your trainer\'s account to unlock your personalized '
        'training experience.',
    details: [
      'Use your trainer\'s invite code to connect in the app',
      'Review and accept your trainer\'s program proposal',
      'Understand your training schedule and check-in expectations',
      'Set communication preferences (notifications, reminders)',
      'Introduce yourself — share your goals and availability',
    ],
    tip:
        'Don\'t hesitate to ask your trainer questions about how the app '
        'works. They\'re there to help you succeed.',
  ),
  _GuideStep(
    number: 3,
    icon: Icons.timer_outlined,
    title: 'Log Your Workouts',
    brief:
        'Track every workout session to see your progress and keep your '
        'trainer informed.',
    details: [
      'Start a workout session from your assigned program or free mode',
      'Log exercises, sets, reps, and weights as you train',
      'Use the rest timer to optimize your recovery between sets',
      'Add notes to exercises — how did the set feel? Any adjustments?',
      'Complete and review each session to track volume and PRs',
    ],
    tip:
        'Log your exercises during (not after) your workout for the most '
        'accurate data and better form feedback from your trainer.',
  ),
  _GuideStep(
    number: 4,
    icon: Icons.water_drop_outlined,
    title: 'Track Daily Habits',
    brief:
        'Build healthy routines by tracking nutrition, hydration, and '
        'wellness metrics.',
    details: [
      'Log your daily water intake to stay hydrated',
      'Track meals and calories to support your nutrition goals',
      'Record daily steps and activity level',
      'Monitor sleep quality and duration for recovery insights',
      'Set daily targets and check them off as you go',
    ],
    tip:
        'Small daily habits compound into big results. Focus on consistency '
        'over perfection — even 80% compliance drives real progress.',
  ),
  _GuideStep(
    number: 5,
    icon: Icons.trending_up_outlined,
    title: 'Monitor Your Progress',
    brief:
        'See how far you\'ve come with visual progress tracking and '
        'achievement celebrations.',
    details: [
      'View your workout history with detailed session data',
      'Track body measurements and transformation photos over time',
      'See your personal records (PRs) for key exercises',
      'Review your check-in history and trainer feedback',
      'Celebrate achievements — streaks, milestone badges, goal completions',
    ],
    tip:
        'Take your progress photos and measurements on the same day each '
        'week for the most consistent tracking results.',
  ),
];

// ---------------------------------------------------------------------------
// Getting Started Guide Screen
// ---------------------------------------------------------------------------

/// An educational guide screen that walks users through the key features of
/// Ziro Fit, with content tailored to trainers and clients.
///
/// This is a reference guide (not the onboarding flow) accessible from
/// the More / Settings menu. It displays 5 sequential steps with expandable
/// cards showing detailed guidance and actionable tips.
class GettingStartedScreen extends ConsumerStatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  ConsumerState<GettingStartedScreen> createState() =>
      _GettingStartedScreenState();
}

class _GettingStartedScreenState extends ConsumerState<GettingStartedScreen> {
  final Set<int> _expandedSteps = {};
  bool _showTrainerContent = true;

  @override
  void initState() {
    super.initState();
    // Auto-expand the first step on open for a guided feel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _expandedSteps.add(0));
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the detected role, but allow manual toggle
    final autoTrainer = authState.isTrainer;
    final effectiveTrainer = autoTrainer ? true : _showTrainerContent;
    final steps = effectiveTrainer ? _trainerSteps : _clientSteps;
    final roleLabel = effectiveTrainer ? 'Trainer Guide' : 'Client Guide';
    final roleIcon =
        effectiveTrainer ? Icons.fitness_center : Icons.person_outline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started Guide'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Header Section --
              _buildHeader(
                theme: theme,
                colorScheme: colorScheme,
                roleLabel: roleLabel,
                roleIcon: roleIcon,
              ),
              const SizedBox(height: 24),

              // -- Role Toggle (only shown for clients) --
              if (!autoTrainer) ...[
                _buildRoleToggle(
                  theme: theme,
                  colorScheme: colorScheme,
                  isTrainer: effectiveTrainer,
                ),
                const SizedBox(height: 20),
              ],

              // -- Step Progress Indicator --
              _buildStepIndicator(
                theme: theme,
                colorScheme: colorScheme,
                stepCount: steps.length,
                expandedCount: _expandedSteps.length,
              ),
              const SizedBox(height: 20),

              // -- Step Cards --
              ...List.generate(steps.length, (i) {
                final step = steps[i];
                final isExpanded = _expandedSteps.contains(i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StepCard(
                    step: step,
                    isExpanded: isExpanded,
                    onToggle: () => _toggleStep(i),
                  ),
                );
              }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleStep(int index) {
    setState(() {
      if (_expandedSteps.contains(index)) {
        _expandedSteps.remove(index);
      } else {
        _expandedSteps.add(index);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  Widget _buildHeader({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String roleLabel,
    required IconData roleIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.explore_outlined,
            size: 32,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to Ziro Fit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This guide walks you through the essential steps to get the '
          'most out of the app. Tap any step to expand it and learn more.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 16, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 6),
              Text(
                roleLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Role Toggle (for client-role users who want to see the trainer guide)
  // --------------------------------------------------------------------------

  Widget _buildRoleToggle({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isTrainer,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viewing as',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoleToggleOption(
                    label: 'Client Guide',
                    icon: Icons.person_outline,
                    isSelected: !isTrainer,
                    onTap: () => setState(() => _showTrainerContent = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleToggleOption(
                    label: 'Trainer Guide',
                    icon: Icons.fitness_center,
                    isSelected: isTrainer,
                    onTap: () => setState(() => _showTrainerContent = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTrainer
                  ? 'Showing the trainer\'s perspective on using Ziro Fit.'
                  : 'Showing the client\'s perspective on using Ziro Fit.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step Progress Indicator
  // --------------------------------------------------------------------------

  Widget _buildStepIndicator({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int stepCount,
    required int expandedCount,
  }) {
    return Row(
      children: [
        Text(
          'Steps',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$expandedCount of $stepCount expanded',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // Dots
        ...List.generate(stepCount, (i) {
          final isActive = _expandedSteps.contains(i);
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Role Toggle Option
// ---------------------------------------------------------------------------

class _RoleToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleToggleOption({
    required this.label,
    required this.icon,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Card
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  final _GuideStep step;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _StepCard({
    required this.step,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isExpanded ? 2 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable header area
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: isExpanded
                    ? Radius.zero
                    : const Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    _StepNumberBadge(
                      number: step.number,
                      isExpanded: isExpanded,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Icon + Title
                              Icon(
                                step.icon,
                                size: 20,
                                color: isExpanded
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.brief,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand/collapse icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(theme, colorScheme),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details
            ...step.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tip
            if (step.tip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.emoji_objects_outlined,
                      size: 18,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.tip!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Number Badge
// ---------------------------------------------------------------------------

class _StepNumberBadge extends StatelessWidget {
  final int number;
  final bool isExpanded;
  final ColorScheme colorScheme;

  const _StepNumberBadge({
    required this.number,
    required this.isExpanded,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isExpanded
            ? colorScheme.primary
            : colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isExpanded
                ? colorScheme.onPrimary
                : colorScheme.primary,
          ),
          child: Text(
            number.toString().padLeft(2, '0'),
          ),
        ),
      ),
    );
  }
}
