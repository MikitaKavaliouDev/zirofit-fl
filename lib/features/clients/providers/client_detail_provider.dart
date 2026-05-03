import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientDetailState {
  final Client? client;
  final List<ClientMeasurement> measurements;
  final List<ClientProgressPhoto> photos;
  final List<WorkoutSession> sessions;
  final bool isLoadingClient;
  final bool isLoadingMeasurements;
  final bool isLoadingPhotos;
  final bool isLoadingSessions;
  final String? error;

  const ClientDetailState({
    this.client,
    this.measurements = const [],
    this.photos = const [],
    this.sessions = const [],
    this.isLoadingClient = false,
    this.isLoadingMeasurements = false,
    this.isLoadingPhotos = false,
    this.isLoadingSessions = false,
    this.error,
  });

  ClientDetailState copyWith({
    Client? client,
    List<ClientMeasurement>? measurements,
    List<ClientProgressPhoto>? photos,
    List<WorkoutSession>? sessions,
    bool? isLoadingClient,
    bool? isLoadingMeasurements,
    bool? isLoadingPhotos,
    bool? isLoadingSessions,
    String? error,
    bool clearError = false,
  }) {
    return ClientDetailState(
      client: client ?? this.client,
      measurements: measurements ?? this.measurements,
      photos: photos ?? this.photos,
      sessions: sessions ?? this.sessions,
      isLoadingClient: isLoadingClient ?? this.isLoadingClient,
      isLoadingMeasurements:
          isLoadingMeasurements ?? this.isLoadingMeasurements,
      isLoadingPhotos: isLoadingPhotos ?? this.isLoadingPhotos,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoading =>
      isLoadingClient ||
      isLoadingMeasurements ||
      isLoadingPhotos ||
      isLoadingSessions;

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientDetailNotifier extends StateNotifier<ClientDetailState> {
  final ApiClient _apiClient;
  final String clientId;

  ClientDetailNotifier({
    required ApiClient apiClient,
    required this.clientId,
  })  : _apiClient = apiClient,
        super(const ClientDetailState());

  // -- Fetch all data at once --

  Future<void> fetchAll() async {
    await Future.wait([
      fetchClient(),
      fetchMeasurements(),
      fetchPhotos(),
      fetchSessions(),
    ]);
  }

  // -- Client details --

  Future<void> fetchClient() async {
    state = state.copyWith(isLoadingClient: true, clearError: true);

    try {
      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId',
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final client = Client.fromJson(rawData);
        state = state.copyWith(client: client, isLoadingClient: false);
      } else {
        state = state.copyWith(
          isLoadingClient: false,
          error: 'Client not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingClient: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Measurements --

  Future<void> fetchMeasurements() async {
    state = state.copyWith(isLoadingMeasurements: true);

    try {
      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/measurements',
      );

      final measurements = _parseList<ClientMeasurement>(
        response['data'],
        ClientMeasurement.fromJson,
      );

      state = state.copyWith(
        measurements: measurements,
        isLoadingMeasurements: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMeasurements: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Adds a new measurement record.
  Future<String?> addMeasurement({
    required DateTime measurementDate,
    double? weightKg,
    double? bodyFatPercentage,
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.clients}/$clientId/measurements',
        body: {
          'measurement_date':
              measurementDate.millisecondsSinceEpoch,
          'weight_kg': ?weightKg,
          'body_fat_percentage': ?bodyFatPercentage,
          'notes': ?notes,
        },
      );
      await fetchMeasurements();
      return null;
    } catch (e) {
      return _extractErrorMessage(e);
    }
  }

  // -- Photos --

  Future<void> fetchPhotos() async {
    state = state.copyWith(isLoadingPhotos: true);

    try {
      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/photos',
      );

      final photos = _parseList<ClientProgressPhoto>(
        response['data'],
        ClientProgressPhoto.fromJson,
      );

      state = state.copyWith(photos: photos, isLoadingPhotos: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingPhotos: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Uploads a progress photo using FormData.
  Future<String?> uploadPhoto({
    required String imagePath,
    DateTime? photoDate,
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'photo_date':
            (photoDate ?? DateTime.now()).millisecondsSinceEpoch,
        'caption': ?caption,
      });

      await _apiClient.dio.post(
        '${ApiConstants.clients}/$clientId/photos',
        data: formData,
      );
      await fetchPhotos();
      return null;
    } catch (e) {
      return _extractErrorMessage(e);
    }
  }

  // -- Sessions --

  Future<void> fetchSessions() async {
    state = state.copyWith(isLoadingSessions: true);

    try {
      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/sessions',
      );

      final sessions = _parseList<WorkoutSession>(
        response['data'],
        WorkoutSession.fromJson,
      );

      state = state.copyWith(
        sessions: sessions,
        isLoadingSessions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSessions: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is List) {
      return data
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

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

// ---------------------------------------------------------------------------
// Provider (family by clientId)
// ---------------------------------------------------------------------------

final clientDetailProvider = StateNotifierProvider.family<
    ClientDetailNotifier, ClientDetailState, String>(
  (ref, clientId) {
    final apiClient = ApiClient.instance;
    return ClientDetailNotifier(apiClient: apiClient, clientId: clientId);
  },
);
