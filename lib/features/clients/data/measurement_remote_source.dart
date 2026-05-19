import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/body_measurement.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';

/// Provider for [MeasurementRemoteSource].
final measurementRemoteSourceProvider = Provider<MeasurementRemoteSource>((ref) {
  return MeasurementRemoteSource(apiClient: ApiClient.instance);
});

/// Remote (and local) data source for all measurement-related API calls.
///
/// Client measurements (weight / body fat) are fetched from the API.
/// Body-part measurements (neck, shoulders, biceps, …) are stored locally
/// in SharedPreferences since the backend does not provide a dedicated CRUD
/// endpoint for them.
class MeasurementRemoteSource {
  final ApiClient _apiClient;

  MeasurementRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  static const _bodyMeasurementsPrefix = 'body_measurements_';

  // ---------------------------------------------------------------------------
  // Client measurements (weight, body fat) – API backed
  // ---------------------------------------------------------------------------

  /// Fetches client measurement records from the API.
  Future<List<ClientMeasurement>> fetchClientMeasurements({
    required String clientId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.clients}/$clientId/measurements',
    );

    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => ClientMeasurement.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a new client measurement record via the API.
  Future<ClientMeasurement> createClientMeasurement({
    required String clientId,
    required DateTime measurementDate,
    double? weightKg,
    double? bodyFatPercentage,
    String? notes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.clients}/$clientId/measurements',
      body: {
        'measurementDate': measurementDate.toIso8601String().split('T')[0],
        'weightKg': ?weightKg,
        'bodyFatPercentage': ?bodyFatPercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return ClientMeasurement.fromJson(data);
    }
    throw Exception('Failed to create measurement');
  }

  // ---------------------------------------------------------------------------
  // Body measurements – API first with SharedPreferences fallback
  // ---------------------------------------------------------------------------

  /// Retrieves all body measurements for a given [clientId].
  ///
  /// Tries the API first. Falls back to local SharedPreferences on failure.
  Future<List<BodyMeasurement>> fetchBodyMeasurements({
    required String clientId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.clientBodyMeasurements(clientId),
      );
      final data = response['data'] as Map<String, dynamic>?;
      final list = data?['measurements'] as List<dynamic>? ?? [];
      final measurements = list
          .map((e) => BodyMeasurement.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sync to local storage for offline access
      await _saveBodyMeasurements(clientId: clientId, measurements: measurements);
      return measurements;
    } catch (_) {
      // Fallback to local storage
      return _loadBodyMeasurementsFromLocal(clientId: clientId);
    }
  }

  /// Stores a new body measurement.
  ///
  /// Tries the API first. Falls back to local storage on failure.
  Future<BodyMeasurement> createBodyMeasurement({
    required String clientId,
    required String type,
    required String typeName,
    required double valueCm,
    String unit = 'cm',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.clientBodyMeasurements(clientId),
        body: {
          'type': type,
          'typeName': typeName,
          'valueCm': valueCm,
          'unit': unit,
          'measuredAt': DateTime.now().toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>?;
      final measurementJson = data?['measurement'] as Map<String, dynamic>?;
      if (measurementJson != null) {
        final measurement =
            BodyMeasurement.fromJson(measurementJson);
        // Sync to local
        await _upsertBodyMeasurementLocal(clientId: clientId, measurement: measurement);
        return measurement;
      }
      throw Exception('Failed to parse created measurement');
    } catch (_) {
      // Fallback: save locally
      return _createBodyMeasurementLocal(
        clientId: clientId,
        type: type,
        typeName: typeName,
        valueCm: valueCm,
        unit: unit,
      );
    }
  }

  /// Updates the value of an existing body measurement.
  ///
  /// Tries the API first. Falls back to local storage on failure.
  Future<BodyMeasurement> updateBodyMeasurement({
    required String clientId,
    required String measurementId,
    required double valueCm,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiConstants.clientBodyMeasurement(clientId, measurementId),
        body: {'valueCm': valueCm},
      );
      final data = response['data'] as Map<String, dynamic>?;
      final measurementJson = data?['measurement'] as Map<String, dynamic>?;
      if (measurementJson != null) {
        final measurement =
            BodyMeasurement.fromJson(measurementJson);
        // Sync to local (upsert in case local doesn't have it yet)
        await _upsertBodyMeasurementLocal(clientId: clientId, measurement: measurement);
        return measurement;
      }
      throw Exception('Failed to parse updated measurement');
    } catch (_) {
      // Fallback: update locally
      return _updateBodyMeasurementLocal(
        clientId: clientId,
        measurementId: measurementId,
        valueCm: valueCm,
      );
    }
  }

  /// Deletes a body measurement by [measurementId].
  ///
  /// Tries the API first. Falls back to local storage on failure.
  Future<void> deleteBodyMeasurement({
    required String clientId,
    required String measurementId,
  }) async {
    try {
      await _apiClient.delete(
        ApiConstants.clientBodyMeasurement(clientId, measurementId),
      );
      // Also remove from local if API succeeded
      await _deleteBodyMeasurementLocal(
        clientId: clientId,
        measurementId: measurementId,
      );
    } catch (_) {
      // Fallback: delete locally
      await _deleteBodyMeasurementLocal(
        clientId: clientId,
        measurementId: measurementId,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Local storage helpers (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<List<BodyMeasurement>> _loadBodyMeasurementsFromLocal({
    required String clientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_bodyMeasurementsPrefix$clientId');
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => BodyMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveBodyMeasurements({
    required String clientId,
    required List<BodyMeasurement> measurements,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(measurements.map((m) => m.toJson()).toList());
    await prefs.setString('$_bodyMeasurementsPrefix$clientId', jsonStr);
  }

  /// Inserts or updates a body measurement in local storage.
  Future<void> _upsertBodyMeasurementLocal({
    required String clientId,
    required BodyMeasurement measurement,
  }) async {
    final measurements = await _loadBodyMeasurementsFromLocal(clientId: clientId);
    final existingIndex = measurements.indexWhere((m) => m.id == measurement.id);
    if (existingIndex >= 0) {
      measurements[existingIndex] = measurement;
    } else {
      measurements.add(measurement);
    }
    await _saveBodyMeasurements(clientId: clientId, measurements: measurements);
  }

  Future<BodyMeasurement> _createBodyMeasurementLocal({
    required String clientId,
    required String type,
    required String typeName,
    required double valueCm,
    String unit = 'cm',
  }) async {
    final now = DateTime.now();
    final measurement = BodyMeasurement(
      id: _generateId(),
      clientId: clientId,
      type: type,
      typeName: typeName,
      valueCm: valueCm,
      unit: unit,
      measuredAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final measurements = await _loadBodyMeasurementsFromLocal(clientId: clientId);
    measurements.add(measurement);
    await _saveBodyMeasurements(clientId: clientId, measurements: measurements);
    return measurement;
  }

  Future<BodyMeasurement> _updateBodyMeasurementLocal({
    required String clientId,
    required String measurementId,
    required double valueCm,
  }) async {
    final measurements = await _loadBodyMeasurementsFromLocal(clientId: clientId);
    final index = measurements.indexWhere((m) => m.id == measurementId);
    if (index == -1) throw Exception('Body measurement not found');

    final updated = measurements[index].copyWith(
      valueCm: valueCm,
      updatedAt: DateTime.now(),
    );

    measurements[index] = updated;
    await _saveBodyMeasurements(clientId: clientId, measurements: measurements);
    return updated;
  }

  Future<void> _deleteBodyMeasurementLocal({
    required String clientId,
    required String measurementId,
  }) async {
    final measurements = await _loadBodyMeasurementsFromLocal(clientId: clientId);
    measurements.removeWhere((m) => m.id == measurementId);
    await _saveBodyMeasurements(clientId: clientId, measurements: measurements);
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(99999).toString().padLeft(5, '0');
    return 'bm_${timestamp}_$suffix';
  }

  final Random _random = Random();
}
