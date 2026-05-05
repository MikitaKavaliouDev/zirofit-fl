import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/features/clients/data/measurement_remote_source.dart';

// =============================================================================
// ClientMeasurementNotifier – weight / body fat tracking (API backed)
// =============================================================================

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

/// State for the client's own weight and body fat measurements.
class ClientMeasurementState {
  final List<ClientMeasurement> measurements;
  final bool isLoading;
  final String? error;

  const ClientMeasurementState({
    this.measurements = const [],
    this.isLoading = false,
    this.error,
  });

  ClientMeasurementState copyWith({
    List<ClientMeasurement>? measurements,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClientMeasurementState(
      measurements: measurements ?? this.measurements,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

/// Notifier for fetching and managing the client's weight / body fat
/// measurement history. Data is read from the `/client/progress` endpoint.
class ClientMeasurementNotifier extends StateNotifier<ClientMeasurementState> {
  final ApiClient _apiClient;

  ClientMeasurementNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ClientMeasurementState());

  /// Fetches the client's progress (weight & body-fat data points) and
  /// converts them into [ClientMeasurement] records.
  Future<void> fetchMeasurements() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get(
        ApiConstants.clientProgress,
        queryParams: null,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final progress = ClientProgress.fromJson(data);

      state = state.copyWith(
        measurements: _mergeProgressIntoMeasurements(progress),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Converts [ClientProgress] weight / body-fat data points into a sorted
  /// list of [ClientMeasurement] objects. Data points on the same date are
  /// merged into a single measurement record.
  List<ClientMeasurement> _mergeProgressIntoMeasurements(
    ClientProgress progress,
  ) {
    // Group MetricPoints by date (date-only comparison)
    final Map<int, ClientMeasurementBuilder> builders = {};

    for (final point in progress.weight) {
      final day = DateTime(
        point.date.year,
        point.date.month,
        point.date.day,
      );
      final key = day.millisecondsSinceEpoch;
      builders.putIfAbsent(key, () => ClientMeasurementBuilder(date: day));
      builders[key]!.weightKg = point.value;
    }

    for (final point in progress.bodyFat) {
      final day = DateTime(
        point.date.year,
        point.date.month,
        point.date.day,
      );
      final key = day.millisecondsSinceEpoch;
      builders.putIfAbsent(key, () => ClientMeasurementBuilder(date: day));
      builders[key]!.bodyFatPercentage = point.value;
    }

    final measurements = builders.values.map((b) => b.build()).toList();
    measurements.sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
    return measurements;
  }

  /// Posts a new measurement through the client measurements endpoint, then
  /// refreshes the local list. Returns `null` on success or an error message.
  Future<String?> addMeasurement({
    required double? weightKg,
    required double? bodyFatPercentage,
    DateTime? measurementDate,
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.clients}/_current/measurements',
        body: {
          'measurementDate':
              (measurementDate ?? DateTime.now()).toIso8601String().split('T')[0],
          'weightKg': ?weightKg,
          'bodyFatPercentage': ?bodyFatPercentage,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      await fetchMeasurements();
      return null;
    } catch (e) {
      return _extractErrorMessage(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

/// Helper to progressively build a [ClientMeasurement] from potentially
/// separate weight and body-fat data points.
class ClientMeasurementBuilder {
  final DateTime date;
  double? weightKg;
  double? bodyFatPercentage;

  ClientMeasurementBuilder({required this.date});

  ClientMeasurement build() {
    return ClientMeasurement(
      id: 'progress_${date.millisecondsSinceEpoch}',
      clientId: '',
      measurementDate: date,
      weightKg: weightKg,
      bodyFatPercentage: bodyFatPercentage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// -----------------------------------------------------------------------------
// Provider
// -----------------------------------------------------------------------------

/// Provider for the client's own weight / body-fat measurements.
final clientMeasurementProvider =
    StateNotifierProvider<ClientMeasurementNotifier, ClientMeasurementState>(
        (ref) {
  final apiClient = ApiClient.instance;
  return ClientMeasurementNotifier(apiClient: apiClient);
});

// =============================================================================
// BodyMeasurementNotifier – body-part measurements (local storage)
// =============================================================================

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

/// State for body-part specific measurements stored locally.
class BodyMeasurementState {
  final List<BodyMeasurement> measurements;
  final Map<String, List<BodyMeasurement>> historyByType;
  final bool isLoading;
  final String? error;

  const BodyMeasurementState({
    this.measurements = const [],
    this.historyByType = const {},
    this.isLoading = false,
    this.error,
  });

  BodyMeasurementState copyWith({
    List<BodyMeasurement>? measurements,
    Map<String, List<BodyMeasurement>>? historyByType,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BodyMeasurementState(
      measurements: measurements ?? this.measurements,
      historyByType: historyByType ?? this.historyByType,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;

  /// Rebuilds [historyByType] from the current [measurements] list.
  BodyMeasurementState withRebuiltHistory() {
    final byType = <String, List<BodyMeasurement>>{};
    for (final m in measurements) {
      byType.putIfAbsent(m.type, () => []);
      byType[m.type]!.add(m);
    }
    // Sort each list newest-first
    for (final list in byType.values) {
      list.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    }
    return copyWith(historyByType: byType);
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

/// Notifier for managing body-part specific measurements (neck, shoulders,
/// chest, biceps, etc.) that are stored locally via [MeasurementRemoteSource].
class BodyMeasurementNotifier extends StateNotifier<BodyMeasurementState> {
  final MeasurementRemoteSource _remoteSource;

  BodyMeasurementNotifier({required MeasurementRemoteSource remoteSource})
      : _remoteSource = remoteSource,
        super(const BodyMeasurementState());

  /// Loads all body measurements for the given [clientId] from local storage.
  Future<void> fetchMeasurements({required String clientId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final measurements =
          await _remoteSource.fetchBodyMeasurements(clientId: clientId);
      state = BodyMeasurementState(measurements: measurements)
          .withRebuiltHistory()
          .copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Creates a new body measurement locally.
  Future<String?> addMeasurement({
    required String clientId,
    required String type,
    required String typeName,
    required double valueCm,
    String unit = 'cm',
  }) async {
    try {
      final measurement = await _remoteSource.createBodyMeasurement(
        clientId: clientId,
        type: type,
        typeName: typeName,
        valueCm: valueCm,
        unit: unit,
      );
      state = state.copyWith(
        measurements: [...state.measurements, measurement],
      ).withRebuiltHistory();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates the value of an existing body measurement.
  Future<String?> updateMeasurement({
    required String clientId,
    required String measurementId,
    required double valueCm,
  }) async {
    try {
      final updated = await _remoteSource.updateBodyMeasurement(
        clientId: clientId,
        measurementId: measurementId,
        valueCm: valueCm,
      );
      final index =
          state.measurements.indexWhere((m) => m.id == measurementId);
      if (index == -1) return 'Measurement not found';
      final updatedList = [...state.measurements];
      updatedList[index] = updated;
      state =
          BodyMeasurementState(measurements: updatedList).withRebuiltHistory();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a body measurement.
  Future<String?> deleteMeasurement({
    required String clientId,
    required String measurementId,
  }) async {
    try {
      await _remoteSource.deleteBodyMeasurement(
        clientId: clientId,
        measurementId: measurementId,
      );
      state = state.copyWith(
        measurements:
            state.measurements.where((m) => m.id != measurementId).toList(),
      ).withRebuiltHistory();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// -----------------------------------------------------------------------------
// Provider
// -----------------------------------------------------------------------------

/// Provider for body-part specific measurements.
final bodyMeasurementProvider =
    StateNotifierProvider<BodyMeasurementNotifier, BodyMeasurementState>(
        (ref) {
  final remoteSource = ref.watch(measurementRemoteSourceProvider);
  return BodyMeasurementNotifier(remoteSource: remoteSource);
});
