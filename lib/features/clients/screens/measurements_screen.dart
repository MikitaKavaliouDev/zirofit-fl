import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/providers/measurement_provider.dart';
import 'package:zirofit_fl/features/clients/screens/measurement_history_screen.dart';
import 'package:zirofit_fl/features/clients/widgets/add_measurement_sheet.dart';
import 'package:zirofit_fl/features/clients/widgets/measurement_type_row.dart';

/// Main measurements screen showing both core metrics (weight, body fat,
/// height) and body-part measurements in a two-section list.
///
/// Follows the iOS pattern in MeasurementsView.swift with a Core section and
/// a Body Part section. Core values are read from [clientMeasurementProvider]
/// (API-backed), body parts from [bodyMeasurementProvider] (local storage).
class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() =>
      _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  // ---------------------------------------------------------------------------
  // Measurement type definitions matching the iOS layout.
  // ---------------------------------------------------------------------------

  static const _coreTypes = [
    MeasurementType(
      id: 'weight',
      name: 'Weight',
      category: 'core',
      unit: 'kg',
    ),
    MeasurementType(
      id: 'body_fat',
      name: 'Body Fat',
      category: 'core',
      unit: '%',
    ),
    MeasurementType(
      id: 'height',
      name: 'Height',
      category: 'core',
      unit: 'cm',
    ),
  ];

  static const _bodyPartTypes = [
    MeasurementType(id: 'neck', name: 'Neck', category: 'bodyPart'),
    MeasurementType(id: 'shoulders', name: 'Shoulders', category: 'bodyPart'),
    MeasurementType(id: 'chest', name: 'Chest', category: 'bodyPart'),
    MeasurementType(
        id: 'left_bicep', name: 'Left Bicep', category: 'bodyPart'),
    MeasurementType(
        id: 'right_bicep', name: 'Right Bicep', category: 'bodyPart'),
    MeasurementType(
        id: 'left_forearm', name: 'Left Forearm', category: 'bodyPart'),
    MeasurementType(
        id: 'right_forearm', name: 'Right Forearm', category: 'bodyPart'),
    MeasurementType(id: 'waist', name: 'Waist', category: 'bodyPart'),
    MeasurementType(id: 'hips', name: 'Hips', category: 'bodyPart'),
    MeasurementType(
        id: 'left_thigh', name: 'Left Thigh', category: 'bodyPart'),
    MeasurementType(
        id: 'right_thigh', name: 'Right Thigh', category: 'bodyPart'),
    MeasurementType(
        id: 'left_calf', name: 'Left Calf', category: 'bodyPart'),
    MeasurementType(
        id: 'right_calf', name: 'Right Calf', category: 'bodyPart'),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(clientMeasurementProvider.notifier).fetchMeasurements();
      final clientId = ref.read(authProvider).user?.id ?? '';
      if (clientId.isNotEmpty) {
        ref
            .read(bodyMeasurementProvider.notifier)
            .fetchMeasurements(clientId: clientId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientMeasurementProvider);
    final bodyState = ref.watch(bodyMeasurementProvider);

    final isLoading = clientState.isLoading || bodyState.isLoading;

    // Compute latest values
    final latestWeight = _latestValue<double>(
      clientState.measurements,
      (m) => m.weightKg,
    );
    final latestBodyFat = _latestValue<double>(
      clientState.measurements,
      (m) => m.bodyFatPercentage,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => _openHistory(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                // -----------------------------------------------------------
                // CORE section
                // -----------------------------------------------------------
                const _SectionHeader(title: 'CORE'),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildCoreRow(
                          type: _coreTypes[0],
                          value: latestWeight != null
                              ? '${latestWeight.toStringAsFixed(1)} kg'
                              : null,
                          onTap: () => _openAddSheet(_coreTypes[0]),
                        ),
                        const Divider(height: 1),
                        _buildCoreRow(
                          type: _coreTypes[1],
                          value: latestBodyFat != null
                              ? '${latestBodyFat.toStringAsFixed(1)}%'
                              : null,
                          onTap: () => _openAddSheet(_coreTypes[1]),
                        ),
                        const Divider(height: 1),
                        // Height – placeholder, always shows "Add"
                        _buildCoreRow(
                          type: _coreTypes[2],
                          value: null,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // -----------------------------------------------------------
                // BODY PART section
                // -----------------------------------------------------------
                const _SectionHeader(title: 'BODY PART'),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < _bodyPartTypes.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _buildPartRow(
                            type: _bodyPartTypes[i],
                            value: _bodyPartValue(
                              bodyState,
                              _bodyPartTypes[i],
                            ),
                            onTap: () => _openAddSheet(_bodyPartTypes[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Row builders
  // ---------------------------------------------------------------------------

  Widget _buildCoreRow({
    required MeasurementType type,
    required String? value,
    required VoidCallback onTap,
  }) {
    return MeasurementTypeRow(
      type: type,
      lastValue: value,
      onAdd: onTap,
    );
  }

  Widget _buildPartRow({
    required MeasurementType type,
    required String? value,
    required VoidCallback onTap,
  }) {
    return MeasurementTypeRow(
      type: type,
      lastValue: value,
      onAdd: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _openAddSheet(MeasurementType type) async {
    // Get current weight for weight-change warning
    final clientState = ref.read(clientMeasurementProvider);
    final currentWeightKg = _latestValue<double>(
      clientState.measurements,
      (m) => m.weightKg,
    );

    final result = await showModalBottomSheet<MeasurementSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddMeasurementSheet(
        type: type,
        currentWeightKg: type.id == 'weight' ? currentWeightKg : null,
      ),
    );

    if (result == null || !mounted) return;

    await _saveMeasurement(type, result);
  }

  Future<void> _saveMeasurement(
    MeasurementType type,
    MeasurementSheetResult result,
  ) async {
    final clientId = ref.read(authProvider).user?.id ?? '';
    String? error;

    switch (type.id) {
      case 'weight':
        error = await ref
            .read(clientMeasurementProvider.notifier)
            .addMeasurement(
              weightKg: result.value,
              bodyFatPercentage: null,
              measurementDate: result.date,
              notes: result.notes,
            );
      case 'body_fat':
        error = await ref
            .read(clientMeasurementProvider.notifier)
            .addMeasurement(
              weightKg: null,
              bodyFatPercentage: result.value,
              measurementDate: result.date,
              notes: result.notes,
            );
      default:
        // Body part measurement
        if (clientId.isEmpty) {
          error = 'Unable to identify user. Please log in again.';
          break;
        }
        error = await ref
            .read(bodyMeasurementProvider.notifier)
            .addMeasurement(
              clientId: clientId,
              type: type.id,
              typeName: type.name,
              valueCm: result.value,
            );
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.name} saved successfully!'),
        ),
      );
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Height tracking coming soon!')),
    );
  }

  void _openHistory(BuildContext context) {
    // Default to weight history when the History button is tapped.
    final weightType = _coreTypes[0];
    final clientState = ref.read(clientMeasurementProvider);

    final dataPoints = clientState.measurements
        .where((m) => m.weightKg != null)
        .map((m) => (
              date: m.measurementDate,
              value: m.weightKg!,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementHistoryScreen(
          type: weightType,
          dataPoints: dataPoints,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the most recent non-null value extracted by [extractor] from
  /// the measurements list (which is expected to be sorted newest-first).
  static T? _latestValue<T>(
    List<ClientMeasurement> measurements,
    T? Function(ClientMeasurement) extractor,
  ) {
    for (final m in measurements) {
      final value = extractor(m);
      if (value != null) return value;
    }
    return null;
  }

  /// Returns the formatted last value string for a body-part measurement type,
  /// or `null` if no measurement has been recorded yet.
  String? _bodyPartValue(BodyMeasurementState state, MeasurementType type) {
    final typeHistory = state.historyByType[type.id];
    final last = typeHistory?.isNotEmpty == true ? typeHistory!.first : null;
    if (last == null) return null;
    return '${last.valueCm.toStringAsFixed(1)} ${last.unit}';
  }
}

// =============================================================================
// Section header widget
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
