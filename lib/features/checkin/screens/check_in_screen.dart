import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';

// ---------------------------------------------------------------------------
// Nutrition Compliance enum (shared with provider)
// ---------------------------------------------------------------------------

enum NutritionComplianceOption {
  onTrack('ON_TRACK', 'On Track'),
  mostly('MOSTLY', 'Mostly'),
  offTrack('OFF_TRACK', 'Off Track');

  final String value;
  final String label;
  const NutritionComplianceOption(this.value, this.label);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final PageController _pageController;

  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _sleepController = TextEditingController();
  final _notesController = TextEditingController();

  int _currentStep = 0;
  final DateTime _selectedDate = DateTime.now();
  double _energyLevel = 5;
  double _stressLevel = 5;
  double _digestionLevel = 5;
  NutritionComplianceOption? _nutritionCompliance;
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  XFile? _backPhoto;
  bool _hasAttemptedNext = false;

  static const _stepCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _sleepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  bool _validateCurrentStep() {
    setState(() => _hasAttemptedNext = true);

    switch (_currentStep) {
      case 0:
        return _weightController.text.trim().isNotEmpty &&
            double.tryParse(_weightController.text.trim()) != null;
      case 1:
        return _nutritionCompliance != null;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _stepCount) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep = step;
      _hasAttemptedNext = false;
    });
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    _goToStep(_currentStep + 1);
  }

  void _previousStep() {
    _goToStep(_currentStep - 1);
  }

  // -------------------------------------------------------------------------
  // Photo picker (slot-aware)
  // -------------------------------------------------------------------------

  Future<void> _pickPhotoForSlot(String slot) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final photo = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        switch (slot) {
          case 'front':
            _frontPhoto = photo;
          case 'side':
            _sidePhoto = photo;
          case 'back':
            _backPhoto = photo;
        }
      });
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_nutritionCompliance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select nutrition compliance')),
      );
      return;
    }

    await ref.read(checkInProvider.notifier).submitCheckIn(
          date: _selectedDate,
          weight: double.parse(_weightController.text.trim()),
          waistCm: _waistController.text.trim().isNotEmpty
              ? double.parse(_waistController.text.trim())
              : null,
          sleepHours: _sleepController.text.trim().isNotEmpty
              ? double.parse(_sleepController.text.trim())
              : null,
          energyLevel: _energyLevel.round(),
          stressLevel: _stressLevel.round(),
          hungerLevel: null,
          digestionLevel: _digestionLevel.round(),
          nutritionCompliance: _nutritionCompliance!.value,
          clientNotes: _notesController.text.trim(),
          frontPhoto: _frontPhoto,
          sidePhoto: _sidePhoto,
          backPhoto: _backPhoto,
        );

    if (!mounted) return;

    final state = ref.read(checkInProvider);
    if (state.isSuccess) {
      setState(() {});
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _dismissSuccess() {
    ref.read(checkInProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkInState = ref.watch(checkInProvider);

    // Show success state
    if (checkInState.isSuccess) {
      return _CheckInSuccessView(onDismiss: _dismissSuccess);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'Weekly Review'
              : _currentStep == 1
                  ? 'Biofeedback'
                  : 'Visual Progress',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Last check-in banner
          if (checkInState.lastCheckIn != null)
            _buildLastCheckInBanner(theme, checkInState.lastCheckIn!),

          // Capsule progress bar (iOS style)
          _buildCapsuleProgress(theme),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CheckInStep1(
                  weightController: _weightController,
                  waistController: _waistController,
                  sleepController: _sleepController,
                  hasAttemptedNext: _hasAttemptedNext,
                ),
                _CheckInStep2(
                  energyLevel: _energyLevel,
                  stressLevel: _stressLevel,
                  digestionLevel: _digestionLevel,
                  nutritionCompliance: _nutritionCompliance,
                  hasAttemptedNext: _hasAttemptedNext,
                  onEnergyChanged: (v) => setState(() => _energyLevel = v),
                  onStressChanged: (v) => setState(() => _stressLevel = v),
                  onDigestionChanged: (v) => setState(() => _digestionLevel = v),
                  onNutritionChanged: (v) =>
                      setState(() => _nutritionCompliance = v),
                ),
                _CheckInStep3(
                  frontPhoto: _frontPhoto,
                  sidePhoto: _sidePhoto,
                  backPhoto: _backPhoto,
                  notesController: _notesController,
                  onPickPhoto: _pickPhotoForSlot,
                  onClearPhoto: (slot) => setState(() {
                    switch (slot) {
                      case 'front':
                        _frontPhoto = null;
                      case 'side':
                        _sidePhoto = null;
                      case 'back':
                        _backPhoto = null;
                    }
                  }),
                ),
              ],
            ),
          ),

          // Bottom navigation (iOS style)
          _buildBottomNavigation(theme, checkInState),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // iOS-style capsule progress bar
  // -------------------------------------------------------------------------

  Widget _buildCapsuleProgress(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: List.generate(_stepCount, (i) {
          final isFilled = i <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 6,
              margin: EdgeInsets.only(
                left: i > 0 ? 6 : 0,
                right: i < _stepCount - 1 ? 6 : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isFilled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom navigation (iOS style)
  // -------------------------------------------------------------------------

  Widget _buildBottomNavigation(ThemeData theme, CheckInState checkInState) {
    final isLastStep = _currentStep == _stepCount - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          // Back button (iOS style circle)
          if (_currentStep > 0)
            GestureDetector(
              onTap: checkInState.isSubmitting ? null : _previousStep,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Next / Submit button
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: checkInState.isSubmitting
                    ? null
                    : (isLastStep ? _submit : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep
                      ? Colors.green
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: checkInState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLastStep ? 'Submit Review' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Last check-in banner
  // -------------------------------------------------------------------------

  Widget _buildLastCheckInBanner(ThemeData theme, CheckIn last) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last check-in: ${dateFormat.format(last.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    if (last.weight != null)
                      Text(
                        'Weight: ${last.weight!.toStringAsFixed(1)} kg',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
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

// =============================================================================
// STEP 1 — The Numbers (iOS: PremiumInputCard style)
// =============================================================================

class _CheckInStep1 extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController waistController;
  final TextEditingController sleepController;
  final bool hasAttemptedNext;

  const _CheckInStep1({
    required this.weightController,
    required this.waistController,
    required this.sleepController,
    required this.hasAttemptedNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Numbers',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tracking your physical progress helps us adjust your plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          _PremiumInputCard(
            icon: Icons.monitor_weight_outlined,
            title: 'Current Weight',
            subtitle: 'kg',
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hasError: hasAttemptedNext && weightController.text.trim().isEmpty,
          ),
          const SizedBox(height: 12),

          _PremiumInputCard(
            icon: Icons.straighten_outlined,
            title: 'Waist Circumference',
            subtitle: 'cm (Optional)',
            controller: waistController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          _PremiumInputCard(
            icon: Icons.bedtime_outlined,
            title: 'Avg. Sleep',
            subtitle: 'hrs / night',
            controller: sleepController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 2 — Biofeedback (iOS: PremiumSliderCard style)
// =============================================================================

class _CheckInStep2 extends StatelessWidget {
  final double energyLevel;
  final double stressLevel;
  final double digestionLevel;
  final NutritionComplianceOption? nutritionCompliance;
  final bool hasAttemptedNext;
  final ValueChanged<double> onEnergyChanged;
  final ValueChanged<double> onStressChanged;
  final ValueChanged<double> onDigestionChanged;
  final ValueChanged<NutritionComplianceOption?> onNutritionChanged;

  const _CheckInStep2({
    required this.energyLevel,
    required this.stressLevel,
    required this.digestionLevel,
    required this.nutritionCompliance,
    required this.hasAttemptedNext,
    required this.onEnergyChanged,
    required this.onStressChanged,
    required this.onDigestionChanged,
    required this.onNutritionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biofeedback',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How is your body responding to the training?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          _PremiumSliderCard(
            title: 'Energy Levels',
            icon: Icons.bolt,
            color: Colors.amber,
            value: energyLevel,
            onChanged: onEnergyChanged,
          ),
          const SizedBox(height: 12),

          _PremiumSliderCard(
            title: 'Stress Levels',
            icon: Icons.psychology,
            color: Colors.purple,
            value: stressLevel,
            onChanged: onStressChanged,
          ),
          const SizedBox(height: 12),

          _PremiumSliderCard(
            title: 'Digestion',
            icon: Icons.monitor_heart_outlined,
            color: Colors.green,
            value: digestionLevel,
            onChanged: onDigestionChanged,
          ),
          const SizedBox(height: 20),

          // Nutrition compliance
          Text(
            'Nutrition Compliance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<NutritionComplianceOption>(
            emptySelectionAllowed: true,
            segments: NutritionComplianceOption.values.map((opt) {
              return ButtonSegment(
                value: opt,
                label: Text(opt.label, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            selected: nutritionCompliance != null
                ? {nutritionCompliance!}
                : <NutritionComplianceOption>{},
            onSelectionChanged: (selected) {
              onNutritionChanged(selected.firstOrNull);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (hasAttemptedNext && nutritionCompliance == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                'Please select nutrition compliance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 3 — Visual Progress (iOS: PremiumPhotoPicker style + notes)
// =============================================================================

class _CheckInStep3 extends StatelessWidget {
  final XFile? frontPhoto;
  final XFile? sidePhoto;
  final XFile? backPhoto;
  final TextEditingController notesController;
  final void Function(String slot) onPickPhoto;
  final void Function(String slot) onClearPhoto;

  const _CheckInStep3({
    required this.frontPhoto,
    required this.sidePhoto,
    required this.backPhoto,
    required this.notesController,
    required this.onPickPhoto,
    required this.onClearPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Progress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Photos provide the most honest feedback.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Photo strip (Front, Side, Back)
          Row(
            children: [
              Expanded(
                child: _PremiumPhotoPicker(
                  label: 'Front',
                  icon: Icons.person,
                  photo: frontPhoto,
                  onPick: () => onPickPhoto('front'),
                  onClear: () => onClearPhoto('front'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumPhotoPicker(
                  label: 'Side',
                  icon: Icons.arrow_right_alt,
                  photo: sidePhoto,
                  onPick: () => onPickPhoto('side'),
                  onClear: () => onClearPhoto('side'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumPhotoPicker(
                  label: 'Back',
                  icon: Icons.switch_account,
                  photo: backPhoto,
                  onPick: () => onPickPhoto('back'),
                  onClear: () => onClearPhoto('back'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Notes
          Text(
            'Weekly Notes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Tell your coach about your week, wins, or struggles...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// PremiumInputCard (iOS-style)
// =============================================================================

class _PremiumInputCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool hasError;

  const _PremiumInputCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    this.keyboardType,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Input field
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: hasError
                      ? BorderSide(color: colorScheme.error)
                      : BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PremiumSliderCard (iOS-style)
// =============================================================================

class _PremiumSliderCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  const _PremiumSliderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PremiumSliderCard> createState() => _PremiumSliderCardState();
}

class _PremiumSliderCardState extends State<_PremiumSliderCard> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_PremiumSliderCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 18, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_value.round()}/10',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.color,
              thumbColor: widget.color,
              inactiveTrackColor: widget.color.withValues(alpha: 0.2),
              overlayColor: widget.color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PremiumPhotoPicker (iOS-style)
// =============================================================================

class _PremiumPhotoPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final XFile? photo;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PremiumPhotoPicker({
    required this.label,
    required this.icon,
    required this.photo,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: photo != null
                  ? Colors.transparent
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: photo != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(photo!.path),
                          fit: BoxFit.cover,
                        ),
                        // Remove button overlay
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onClear,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 28, color: theme.colorScheme.primary),
                        const SizedBox(height: 6),
                        Text(
                          'Add',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Success View (iOS-style)
// =============================================================================

class _CheckInSuccessView extends StatelessWidget {
  final VoidCallback onDismiss;

  const _CheckInSuccessView({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark seal
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Great Work!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your check-in has been submitted. Your trainer will review it shortly.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onDismiss,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
