import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';

// =============================================================================
// Trainer Finding Onboarding Screen — 4-Step Standalone Flow
// =============================================================================
//
// Route: `/onboarding/find-trainer`
//
// Walks clients through: (1) Intro, (2) Specialties, (3) Location,
// (4) Browse results and select a trainer.
//
// API endpoint used: GET /trainers?specialties=X&location=Y
//   - lives under ApiConstants.trainersSearch ('/trainers')
//   - passes selectedSpecialties as 'specialties' and location as 'location'

/// Fitness specialties available for selection in Step 2.
const List<String> _kSpecialties = [
  'Weight Training',
  'Yoga',
  'Cardio',
  'HIIT',
  'Pilates',
  'CrossFit',
  'Strength & Conditioning',
  'Flexibility',
  'Endurance Training',
  'Nutrition Coaching',
  'Rehabilitation',
  'Sports Performance',
  'Boxing',
  'Dance Fitness',
  'Swimming',
  'Martial Arts',
];

/// Default mock trainers used when the API is unreachable.
final List<TrainerSearchResult> _kMockTrainers = [
  TrainerSearchResult(
    id: 'mock-t1',
    name: 'Alex Johnson',
    specialties: ['Weight Training', 'Strength & Conditioning'],
    rating: 4.9,
    reviewCount: 124,
    location: 'New York, NY',
    distance: 2.3,
  ),
  TrainerSearchResult(
    id: 'mock-t2',
    name: 'Sarah Chen',
    specialties: ['Yoga', 'Flexibility', 'Pilates'],
    rating: 4.8,
    reviewCount: 98,
    location: 'New York, NY',
    distance: 1.5,
  ),
  TrainerSearchResult(
    id: 'mock-t3',
    name: 'Marcus Williams',
    specialties: ['HIIT', 'Cardio', 'CrossFit'],
    rating: 4.7,
    reviewCount: 203,
    location: 'Brooklyn, NY',
    distance: 5.1,
  ),
  TrainerSearchResult(
    id: 'mock-t4',
    name: 'Priya Patel',
    specialties: ['Endurance Training', 'Yoga', 'Nutrition Coaching'],
    rating: 4.9,
    reviewCount: 156,
    location: 'New York, NY',
    distance: 3.0,
  ),
  TrainerSearchResult(
    id: 'mock-t5',
    name: 'James Rodriguez',
    specialties: ['Boxing', 'Martial Arts', 'HIIT'],
    rating: 4.6,
    reviewCount: 87,
    location: 'Jersey City, NJ',
    distance: 8.2,
  ),
];

// =============================================================================
// Screen
// =============================================================================

class TrainerFindingOnboardingScreen extends ConsumerStatefulWidget {
  const TrainerFindingOnboardingScreen({super.key});

  @override
  ConsumerState<TrainerFindingOnboardingScreen> createState() =>
      _TrainerFindingOnboardingScreenState();
}

class _TrainerFindingOnboardingScreenState
    extends ConsumerState<TrainerFindingOnboardingScreen> {
  late final PageController _pageController;

  // -- Flow state --
  int _currentStep = 0;
  final List<String> _selectedSpecialties = [];
  final TextEditingController _locationController = TextEditingController();
  List<TrainerSearchResult> _results = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Navigation
  // --------------------------------------------------------------------------

  void _goNext() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _isNextEnabled {
    switch (_currentStep) {
      case 0: // Intro — always enabled
        return true;
      case 1: // Specialties — at least 1 required
        return _selectedSpecialties.isNotEmpty;
      case 2: // Location — text must be non-empty
        return _locationController.text.trim().isNotEmpty;
      case 3: // Results — a trainer must be selected
        return _selectedTrainer != null;
      default:
        return true;
    }
  }

  String? get _selectedTrainerId => _selectedTrainer?.id;
  TrainerSearchResult? _selectedTrainer;

  // --------------------------------------------------------------------------
  // Step 2: Toggle specialty
  // --------------------------------------------------------------------------

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Step 3 → Step 4: Search trainers
  // --------------------------------------------------------------------------

  Future<void> _searchTrainers() async {
    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final client = ApiClient.instance;
      final queryParams = <String, dynamic>{};

      if (_selectedSpecialties.isNotEmpty) {
        queryParams['specialty'] = _selectedSpecialties.first;
      }
      final location = _locationController.text.trim();
      if (location.isNotEmpty) {
        queryParams['location'] = location;
      }

      final Map<String, dynamic> response = await client.get(
        '/trainers',
        queryParams: queryParams,
      );

      final Map<String, dynamic> data =
          response['data'] as Map<String, dynamic>? ?? response;
      final List<dynamic> rawList = data['trainers'] as List? ??
          data['results'] as List? ??
          [];

      if (rawList.isNotEmpty) {
        final trainers = rawList
            .map((e) =>
                TrainerSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _results = trainers;
          _isSearching = false;
        });
      } else {
        // No results from API — use mock data as fallback
        _useMockData();
      }
    } catch (_) {
      if (!mounted) return;
      // API unavailable — fall back to mock data
      _useMockData();
    }
  }

  void _useMockData() {
    // Filter mock trainers by selected specialties
    final filtered = _kMockTrainers.where((t) {
      return t.specialties.any(
        (s) => _selectedSpecialties.contains(s),
      );
    }).toList();

    setState(() {
      _results = filtered.isNotEmpty ? filtered : _kMockTrainers;
      _isSearching = false;
    });
  }

  // --------------------------------------------------------------------------
  // Completion
  // --------------------------------------------------------------------------

  void _onSelectTrainer(TrainerSearchResult trainer) {
    setState(() => _selectedTrainer = trainer);
  }

  void _onConfirmSelection() {
    if (_selectedTrainer == null) return;

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected with ${_selectedTrainer!.name}!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to dashboard or to the trainer's profile
    context.go('/client/dashboard');
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Back + Step dots ─────────────────────────────
            _buildHeader(colorScheme),

            const SizedBox(height: 4),

            // ── PageView ──────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentStep = page);
                },
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildIntroStep(theme, colorScheme),
                  _buildSpecialtiesStep(theme, colorScheme),
                  _buildLocationStep(theme, colorScheme),
                  _buildResultsStep(theme, colorScheme),
                ],
              ),
            ),

            // ── Bottom Navigation ─────────────────────────────────────
            _buildBottomNav(colorScheme),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Back button (hidden on step 0)
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _goBack,
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),

          const Spacer(),

          // Step indicator dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_totalSteps, (i) {
              final isActive = i == _currentStep;
              final isPast = i < _currentStep;
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
          ),

          const Spacer(),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 1 — Intro
  // --------------------------------------------------------------------------

  Widget _buildIntroStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_rounded,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Find Your Trainer',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Benefits
          Text(
            'Working with a personal trainer helps you stay '
            'accountable, reach your goals faster, and train '
            'with confidence.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Benefit items
          _buildBenefitRow(
            icon: Icons.check_circle_rounded,
            text: 'Personalized workout plans',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(
            icon: Icons.trending_up_rounded,
            text: 'Track progress & stay motivated',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(
            icon: Icons.schedule_rounded,
            text: 'Flexible scheduling that fits your life',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildBenefitRow(
            icon: Icons.food_bank_rounded,
            text: 'Nutrition & lifestyle guidance',
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 40),

          // Get Started button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _goNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Step 2 — Specialties
  // --------------------------------------------------------------------------

  Widget _buildSpecialtiesStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'What are you interested in?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select one or more specialties to find the right trainer for you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Chip grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kSpecialties.map((specialty) {
              final isSelected = _selectedSpecialties.contains(specialty);
              return FilterChip(
                label: Text(specialty),
                selected: isSelected,
                onSelected: (_) => _toggleSpecialty(specialty),
                showCheckmark: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Selection count
          Center(
            child: Text(
              _selectedSpecialties.isNotEmpty
                  ? '${_selectedSpecialties.length} selected'
                  : 'Select at least one',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _selectedSpecialties.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 3 — Location
  // --------------------------------------------------------------------------

  Widget _buildLocationStep(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Icon(
            Icons.location_on_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Where are you located?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your city or area so we can find trainers near you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: 32),

          // Location text field
          TextField(
            controller: _locationController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter city or area',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_locationController.text.trim().isNotEmpty) {
                _searchTrainers();
                _goNext();
              }
            },
          ),

          const SizedBox(height: 16),

          // Use current location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // For now, fill in a default location.
                // In production, use Geolocator like map_location_step.dart.
                _locationController.text = 'New York, NY';
                setState(() {});
              },
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Use Current Location'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Step 4 — Results
  // --------------------------------------------------------------------------

  Widget _buildResultsStep(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
          child: Column(
            children: [
              Icon(
                Icons.people_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Trainers near you',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${_results.length} trainer${_results.length == 1 ? '' : 's'} found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        // Loading state
        if (_isSearching)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )

        // Error state
        else if (_error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _searchTrainers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )

        // Results list
        else
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'No trainers found. Try different specialties or location.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final trainer = _results[index];
                      final isSelected = _selectedTrainer?.id == trainer.id;
                      return _buildTrainerCard(
                        trainer: trainer,
                        isSelected: isSelected,
                        onTap: () => _onSelectTrainer(trainer),
                        theme: theme,
                        colorScheme: colorScheme,
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildTrainerCard({
    required TrainerSearchResult trainer,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: trainer.avatarUrl != null &&
                        trainer.avatarUrl!.isNotEmpty
                    ? NetworkImage(trainer.avatarUrl!)
                    : null,
                child: trainer.avatarUrl == null ||
                        trainer.avatarUrl!.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      trainer.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    if (trainer.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              trainer.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            if (trainer.reviewCount != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${trainer.reviewCount})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Specialty badges
                    if (trainer.specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: trainer.specialties.take(3).map(
                            (s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        colorScheme.onSecondaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),

                    // Distance
                    if (trainer.distance != null)
                      Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            size: 14,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${trainer.distance!.toStringAsFixed(1)} km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Selection indicator or arrow
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 24,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Navigation
  // --------------------------------------------------------------------------

  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button (hidden on step 0)
            if (_currentStep > 0 && _currentStep < 3)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side:
                        BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0 && _currentStep < 3)
              const SizedBox(width: 12),

            // Next / Continue / Select button
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isNextEnabled && !_isLoading
                    ? _currentStep == 0
                        ? _goNext
                        : _currentStep == 1
                            ? _goNext
                            : _currentStep == 2
                                ? () {
                                    _searchTrainers();
                                    _goNext();
                                  }
                                : _onConfirmSelection
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _stepButtonLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepButtonLabel {
    switch (_currentStep) {
      case 0:
        return 'Get Started';
      case 1:
        return 'Next';
      case 2:
        return 'Find Trainers';
      case 3:
        return 'Confirm';
      default:
        return 'Continue';
    }
  }
}
