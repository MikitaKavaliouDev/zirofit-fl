import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 4: Height, weight, age, and gender inputs.
class PhysicalStatsStep extends ConsumerStatefulWidget {
  const PhysicalStatsStep({super.key});

  @override
  ConsumerState<PhysicalStatsStep> createState() => _PhysicalStatsStepState();
}

class _PhysicalStatsStepState extends ConsumerState<PhysicalStatsStep> {
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '70');
  final _ageController = TextEditingController(text: '30');
  String _gender = '';
  bool _useImperial = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Header
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Your Physical Stats',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Help us personalize your experience',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Unit toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Metric',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: !_useImperial ? FontWeight.w600 : null,
                    color: !_useImperial
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Switch(
                  value: _useImperial,
                  onChanged: (v) {
                    setState(() => _useImperial = v);
                    HapticFeedback.lightImpact();
                  },
                ),
                Text(
                  'Imperial',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: _useImperial ? FontWeight.w600 : null,
                    color: _useImperial
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Height
            _NumericStatCard(
              icon: Icons.height_rounded,
              label: 'Height',
              controller: _heightController,
              unit: _useImperial ? 'ft/in' : 'cm',
              keyboardType:
                  _useImperial ? TextInputType.number : TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Weight
            _NumericStatCard(
              icon: Icons.monitor_weight_rounded,
              label: 'Weight',
              controller: _weightController,
              unit: _useImperial ? 'lbs' : 'kg',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Age
            _NumericStatCard(
              icon: Icons.cake_rounded,
              label: 'Age',
              controller: _ageController,
              unit: 'years',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Gender selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gender',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _GenderChip(
                    label: 'Male',
                    icon: Icons.male_rounded,
                    isSelected: _gender == 'male',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _gender = 'male');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderChip(
                    label: 'Female',
                    icon: Icons.female_rounded,
                    isSelected: _gender == 'female',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _gender = 'female');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderChip(
                    label: 'Other',
                    icon: Icons.transgender_rounded,
                    isSelected: _gender == 'other',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _gender = 'other');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NumericStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String unit;
  final TextInputType keyboardType;

  const _NumericStatCard({
    required this.icon,
    required this.label,
    required this.controller,
    required this.unit,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
