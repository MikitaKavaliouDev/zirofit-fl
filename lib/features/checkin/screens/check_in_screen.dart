import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';

// ---------------------------------------------------------------------------
// Nutrition Compliance enum for segmented picker
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
  double _hungerLevel = 5;
  double _digestionLevel = 5;
  NutritionComplianceOption? _nutritionCompliance;
  XFile? _photo;
  bool _hasAttemptedNext = false;

  static const _stepLabels = ['Body Metrics', 'How You Feel', 'Photos', 'Notes'];

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
        final weight = _weightController.text.trim();
        if (weight.isEmpty) return false;
        final parsed = double.tryParse(weight);
        if (parsed == null || parsed <= 0) return false;
        return true;
      case 1:
        return _nutritionCompliance != null;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > 3) return;
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
  // Photo picker
  // -------------------------------------------------------------------------

  Future<void> _pickPhoto() async {
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
      setState(() => _photo = photo);
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
          hungerLevel: _hungerLevel.round(),
          digestionLevel: _digestionLevel.round(),
          nutritionCompliance: _nutritionCompliance!.value,
          clientNotes: _notesController.text.trim(),
          photo: _photo,
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
      return _buildSuccessView(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Check-in'),
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

          // Step indicator
          _buildStepIndicator(theme),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuantitativeStep(theme),
                _buildQualitativeStep(theme),
                _buildPhotosStep(theme),
                _buildNotesStep(theme),
              ],
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(theme, checkInState),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Success view
  // -------------------------------------------------------------------------

  Widget _buildSuccessView(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check-in Submitted!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your trainer has been notified.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _dismissSuccess,
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

  // -------------------------------------------------------------------------
  // Step indicator
  // -------------------------------------------------------------------------

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Step circles + connecting line
          Row(
            children: List.generate(_stepLabels.length, (i) {
              final isCompleted = i < _currentStep;
              final isCurrent = i == _currentStep;

              return Expanded(
                child: _buildStepDot(theme, i, isCompleted, isCurrent),
              );
            }),
          ),
          const SizedBox(height: 6),
          // Labels
          Row(
            children: List.generate(_stepLabels.length, (i) {
              final isActive = i <= _currentStep;
              return Expanded(
                child: Text(
                  _stepLabels[i],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(ThemeData theme, int index, bool isCompleted, bool isCurrent) {
    return Row(
      children: [
        // Dot
        if (index > 0)
          Expanded(
            child: Container(
              height: 2,
              color: index <= _currentStep
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? theme.colorScheme.primary
                : isCurrent
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
            border: Border.all(
              color: isCurrent || isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
                : Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        if (index < _stepLabels.length - 1)
          Expanded(
            child: Container(
              height: 2,
              color: index < _currentStep
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Bottom navigation
  // -------------------------------------------------------------------------

  Widget _buildBottomNavigation(ThemeData theme, CheckInState checkInState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            TextButton(
              onPressed: checkInState.isSubmitting ? null : _previousStep,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text('Back'),
            ),

          if (_currentStep > 0) const Spacer(),

          // Next or Submit button
          FilledButton(
            onPressed: checkInState.isSubmitting
                ? null
                : (_currentStep < 3 ? _nextStep : _submit),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                    _currentStep == 3 ? 'Submit' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 1 — QuantitativeStep
  // -------------------------------------------------------------------------

  Widget _buildQuantitativeStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did your body change?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your key body metrics for this week',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Weight
          Text(
            'Weight (kg) *',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter your weight',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              suffixText: 'kg',
            ),
            onChanged: (_) {
              if (_hasAttemptedNext) setState(() {});
            },
          ),
          if (_hasAttemptedNext && _weightController.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                'Weight is required',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Waist
          Text(
            'Waist (cm)',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _waistController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Optional',
              prefixIcon: Icon(Icons.straighten_outlined),
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 20),

          // Sleep
          Text(
            'Sleep (hrs)',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sleepController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Optional',
              prefixIcon: Icon(Icons.bedtime_outlined),
              suffixText: 'hrs',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 2 — QualitativeStep
  // -------------------------------------------------------------------------

  Widget _buildQualitativeStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you feel?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Rate each on a scale of 1–10',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          _buildSliderCard(
            theme: theme,
            label: 'Energy Level',
            value: _energyLevel,
            onChanged: (v) => setState(() => _energyLevel = v),
            minLabel: 'Very Low',
            maxLabel: 'High Energy',
            icon: Icons.bolt,
          ),
          const SizedBox(height: 8),

          _buildSliderCard(
            theme: theme,
            label: 'Stress Level',
            value: _stressLevel,
            onChanged: (v) => setState(() => _stressLevel = v),
            minLabel: 'Relaxed',
            maxLabel: 'Very Stressed',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 8),

          _buildSliderCard(
            theme: theme,
            label: 'Hunger Level',
            value: _hungerLevel,
            onChanged: (v) => setState(() => _hungerLevel = v),
            minLabel: 'Not Hungry',
            maxLabel: 'Very Hungry',
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 8),

          _buildSliderCard(
            theme: theme,
            label: 'Digestion Level',
            value: _digestionLevel,
            onChanged: (v) => setState(() => _digestionLevel = v),
            minLabel: 'Poor',
            maxLabel: 'Great',
            icon: Icons.monitor_heart_outlined,
          ),
          const SizedBox(height: 24),

          // Nutrition compliance
          Text(
            'Nutrition Compliance *',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
            selected: _nutritionCompliance != null
                ? {_nutritionCompliance!}
                : <NutritionComplianceOption>{},
            onSelectionChanged: (selected) {
              setState(() => _nutritionCompliance = selected.first);
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
          if (_hasAttemptedNext && _nutritionCompliance == null)
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

  Widget _buildSliderCard({
    required ThemeData theme,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String minLabel,
    required String maxLabel,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.round().toString(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    minLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    maxLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 3 — PhotosStep
  // -------------------------------------------------------------------------

  Widget _buildPhotosStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Photos',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Front, Side, Back (Optional)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Photo gallery horizontal scroll
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing photo
                if (_photo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photo!.path),
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _photo = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add photo button
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 4 — NotesStep
  // -------------------------------------------------------------------------

  Widget _buildNotesStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Notes',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Share how your week went with your trainer',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _notesController,
            maxLines: 8,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'How was your week? Any challenges or wins?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Anything else to tell your trainer?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
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
