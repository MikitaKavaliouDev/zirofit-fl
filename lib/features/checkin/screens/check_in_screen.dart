import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/check_in.dart';
import 'package:zirofit_fl/features/checkin/providers/check_in_provider.dart';

// ---------------------------------------------------------------------------
// Nutrition Compliance enum for the dropdown
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
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _sleepController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _energyLevel = 5;
  double _stressLevel = 5;
  double _hungerLevel = 5;
  double _digestionLevel = 5;
  NutritionComplianceOption? _nutritionCompliance;
  XFile? _photo;
  bool _submitted = false;

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _sleepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Date picker
  // -------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 14)),
      lastDate: now,
      helpText: 'Select check-in date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
    if (!_formKey.currentState!.validate()) return;
    if (_nutritionCompliance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select nutrition compliance')),
      );
      return;
    }

    setState(() => _submitted = true);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = DateTime.now();
        _weightController.clear();
        _waistController.clear();
        _sleepController.clear();
        _notesController.clear();
        _energyLevel = 5;
        _stressLevel = 5;
        _hungerLevel = 5;
        _digestionLevel = 5;
        _nutritionCompliance = null;
        _photo = null;
        _submitted = false;
      });
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkInState = ref.watch(checkInProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Check-in'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(checkInProvider.notifier).fetchLastCheckIn(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Last check-in summary (if available)
                if (checkInState.lastCheckIn != null)
                  _buildLastCheckInBanner(theme, checkInState.lastCheckIn!),

                if (checkInState.lastCheckIn != null) const SizedBox(height: 20),

                // Date picker
                _buildSectionLabel(theme, 'Check-in Date'),
                const SizedBox(height: 8),
                _buildDatePicker(theme, dateFormat),
                const SizedBox(height: 20),

                // Weight
                _buildSectionLabel(theme, 'Weight (kg) *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your weight',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Weight is required';
                    }
                    final weight = double.tryParse(v.trim());
                    if (weight == null || weight <= 0) {
                      return 'Enter a valid weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Waist circumference
                _buildSectionLabel(theme, 'Waist Circumference (cm)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _waistController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.straighten_outlined),
                    suffixText: 'cm',
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0) {
                        return 'Enter a valid measurement';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Sleep hours
                _buildSectionLabel(theme, 'Sleep (hours)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sleepController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.bedtime_outlined),
                    suffixText: 'hrs',
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final val = double.tryParse(v.trim());
                      if (val == null || val <= 0 || val > 24) {
                        return 'Enter 0-24 hours';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Sliders ---
                _buildSectionLabel(theme, 'Wellness Metrics'),
                const SizedBox(height: 4),
                Text(
                  'Rate each on a scale of 1–10',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSlider(
                  theme: theme,
                  label: 'Energy Level',
                  value: _energyLevel,
                  onChanged: (v) => setState(() => _energyLevel = v),
                  minLabel: 'Very Low',
                  maxLabel: 'High Energy',
                  icon: Icons.bolt,
                ),
                const SizedBox(height: 8),

                _buildSlider(
                  theme: theme,
                  label: 'Stress Level',
                  value: _stressLevel,
                  onChanged: (v) => setState(() => _stressLevel = v),
                  minLabel: 'Relaxed',
                  maxLabel: 'Very Stressed',
                  icon: Icons.psychology,
                ),
                const SizedBox(height: 8),

                _buildSlider(
                  theme: theme,
                  label: 'Hunger Level',
                  value: _hungerLevel,
                  onChanged: (v) => setState(() => _hungerLevel = v),
                  minLabel: 'Not Hungry',
                  maxLabel: 'Very Hungry',
                  icon: Icons.restaurant,
                ),
                const SizedBox(height: 8),

                _buildSlider(
                  theme: theme,
                  label: 'Digestion Level',
                  value: _digestionLevel,
                  onChanged: (v) => setState(() => _digestionLevel = v),
                  minLabel: 'Poor',
                  maxLabel: 'Great',
                  icon: Icons.monitor_heart_outlined,
                ),
                const SizedBox(height: 24),

                // Nutrition compliance dropdown
                _buildSectionLabel(theme, 'Nutrition Compliance *'),
                const SizedBox(height: 8),
                DropdownButtonFormField<NutritionComplianceOption>(
                  initialValue: _nutritionCompliance,
                  decoration: const InputDecoration(
                    hintText: 'Select compliance level',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: NutritionComplianceOption.values.map((opt) {
                    return DropdownMenuItem(
                      value: opt,
                      child: Text(opt.label),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _nutritionCompliance = v),
                  validator: (v) {
                    if (v == null) return 'Please select compliance level';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Client notes
                _buildSectionLabel(theme, 'Notes for Your Trainer'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Share how your week went...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo upload
                _buildSectionLabel(theme, 'Progress Photo'),
                const SizedBox(height: 8),
                _buildPhotoPicker(theme),
                const SizedBox(height: 28),

                // Submit button
                FilledButton.icon(
                  onPressed: checkInState.isSubmitting ? null : _submit,
                  icon: checkInState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    checkInState.isSubmitting
                        ? 'Submitting...'
                        : 'Submit Check-In',
                  ),
                ),

                // Error banner
                if (checkInState.error != null && _submitted) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(theme, checkInState.error!),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sub-widgets
  // -------------------------------------------------------------------------

  Widget _buildLastCheckInBanner(ThemeData theme, CheckIn last) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last check-in: ${dateFormat.format(last.date)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (last.weight != null)
                    Text(
                      'Weight: ${last.weight!.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme, DateFormat dateFormat) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.calendar_month_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          dateFormat.format(_selectedDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildSlider({
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
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

  Widget _buildPhotoPicker(ThemeData theme) {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: _photo != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_photo!.path),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _photo = null),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _photo!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add Progress Photo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Optional',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
