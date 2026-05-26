import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/data/models/client_measurement.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/client_package.dart';
import 'package:zirofit_fl/data/models/client_progress_photo.dart';
import 'package:zirofit_fl/data/models/enums/workout_session_status.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientDetailState {
  final Client? client;
  final List<ClientMeasurement> measurements;
  final List<ClientProgressPhoto> photos;
  final List<WorkoutSession> sessions;
  final ActiveProgramResponse? activeProgram;
  final List<ClientPackage> clientPackages;
  final bool isLoadingClient;
  final bool isLoadingMeasurements;
  final bool isLoadingPhotos;
  final bool isLoadingSessions;
  final bool isLoadingProgram;
  final bool isLoadingPackages;
  final String? error;

  const ClientDetailState({
    this.client,
    this.measurements = const [],
    this.photos = const [],
    this.sessions = const [],
    this.activeProgram,
    this.clientPackages = const [],
    this.isLoadingClient = false,
    this.isLoadingMeasurements = false,
    this.isLoadingPhotos = false,
    this.isLoadingSessions = false,
    this.isLoadingProgram = false,
    this.isLoadingPackages = false,
    this.error,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientDetailState &&
          client == other.client &&
          listEquals(measurements, other.measurements) &&
          listEquals(photos, other.photos) &&
          listEquals(sessions, other.sessions) &&
          activeProgram == other.activeProgram &&
          listEquals(clientPackages, other.clientPackages) &&
          isLoadingClient == other.isLoadingClient &&
          isLoadingMeasurements == other.isLoadingMeasurements &&
          isLoadingPhotos == other.isLoadingPhotos &&
          isLoadingSessions == other.isLoadingSessions &&
          isLoadingProgram == other.isLoadingProgram &&
          isLoadingPackages == other.isLoadingPackages &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        client,
        Object.hashAll(measurements),
        Object.hashAll(photos),
        Object.hashAll(sessions),
        activeProgram,
        Object.hashAll(clientPackages),
        isLoadingClient,
        isLoadingMeasurements,
        isLoadingPhotos,
        isLoadingSessions,
        isLoadingProgram,
        isLoadingPackages,
        error,
      );

  ClientDetailState copyWith({
    Client? client,
    List<ClientMeasurement>? measurements,
    List<ClientProgressPhoto>? photos,
    List<WorkoutSession>? sessions,
    ActiveProgramResponse? activeProgram,
    List<ClientPackage>? clientPackages,
    bool? isLoadingClient,
    bool? isLoadingMeasurements,
    bool? isLoadingPhotos,
    bool? isLoadingSessions,
    bool? isLoadingProgram,
    bool? isLoadingPackages,
    String? error,
    bool clearError = false,
  }) {
    return ClientDetailState(
      client: client ?? this.client,
      measurements: measurements ?? this.measurements,
      photos: photos ?? this.photos,
      sessions: sessions ?? this.sessions,
      activeProgram: activeProgram ?? this.activeProgram,
      clientPackages: clientPackages ?? this.clientPackages,
      isLoadingClient: isLoadingClient ?? this.isLoadingClient,
      isLoadingMeasurements:
          isLoadingMeasurements ?? this.isLoadingMeasurements,
      isLoadingPhotos: isLoadingPhotos ?? this.isLoadingPhotos,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      isLoadingProgram: isLoadingProgram ?? this.isLoadingProgram,
      isLoadingPackages: isLoadingPackages ?? this.isLoadingPackages,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // -- Computed getters from sessions --

  /// Number of completed workout sessions.
  int get workoutsCount =>
      sessions.where((s) => s.status == WorkoutSessionStatus.completed).length;

  /// Active streak as "X Days" string computed from session dates.
  String get activeStreak {
    if (sessions.isEmpty) return '0 Days';

    final completed = sessions
        .where((s) => s.status == WorkoutSessionStatus.completed)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (completed.isEmpty) return '0 Days';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;
    DateTime checkDate;

    // Check if there's a workout today or yesterday to start the streak
    final hasToday = completed.any((s) =>
        DateTime(s.startTime.year, s.startTime.month, s.startTime.day) ==
        today);
    final hasYesterday = completed.any((s) =>
        DateTime(s.startTime.year, s.startTime.month, s.startTime.day) ==
        yesterday);

    if (hasToday) {
      streak = 1;
      checkDate = yesterday;
    } else if (hasYesterday) {
      checkDate = yesterday;
    } else {
      return '0 Days';
    }

    // Count backwards
    while (true) {
      final hasWorkout = completed.any((s) =>
          DateTime(s.startTime.year, s.startTime.month, s.startTime.day) ==
          checkDate);
      if (hasWorkout) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return '$streak Day${streak == 1 ? '' : 's'}';
  }

  /// Relative time string for the most recent session.
  String get lastSessionTime {
    final completed = sessions
        .where((s) => s.status == WorkoutSessionStatus.completed)
        .toList()
      ..sort((a, b) => (b.endTime ?? b.startTime)
          .compareTo(a.endTime ?? a.startTime));

    if (completed.isEmpty) return 'Never';

    final lastTime = completed.first.endTime ?? completed.first.startTime;
    final diff = DateTime.now().difference(lastTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  bool get isLoading =>
      isLoadingClient ||
      isLoadingMeasurements ||
      isLoadingPhotos ||
      isLoadingSessions ||
      isLoadingProgram ||
      isLoadingPackages;

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
      fetchActiveProgram(),
      fetchClientPackages(),
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
      if (rawData is Map<String, dynamic> && rawData.containsKey('client')) {
        final client = Client.fromJson(rawData['client'] as Map<String, dynamic>);
        state = state.copyWith(client: client, isLoadingClient: false);
      } else if (rawData is Map<String, dynamic> && rawData.containsKey('id')) {
        // Fallback for flat response
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

      final data = response['data'];
      final rawList = data is Map ? data['measurements'] : data;

      final measurements = _parseList<ClientMeasurement>(
        rawList,
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
          'measurementDate':
              measurementDate.toIso8601String().split('T')[0],
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

  // -- Photos --

  Future<void> fetchPhotos() async {
    state = state.copyWith(isLoadingPhotos: true);

    try {
      final response = await _apiClient.get(
        '${ApiConstants.clients}/$clientId/photos',
      );

      final data = response['data'];
      final rawList = data is Map ? data['photos'] : data;

      final photos = _parseList<ClientProgressPhoto>(
        rawList,
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
        'photo': await MultipartFile.fromFile(imagePath),
        'photoDate': (photoDate ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
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

      final data = response['data'];
      final rawList = data is Map ? data['sessions'] : data;

      final sessions = _parseList<WorkoutSession>(
        rawList,
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

  // -- Active Program --

  Future<void> fetchActiveProgram() async {
    state = state.copyWith(isLoadingProgram: true);

    try {
      final response = await _apiClient.get(
        ApiConstants.trainerClientActiveProgram(clientId),
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final program = ActiveProgramResponse.fromJson(rawData);
        state = state.copyWith(
          activeProgram: program,
          isLoadingProgram: false,
        );
      } else {
        state = state.copyWith(isLoadingProgram: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingProgram: false);
    }
  }

  // -- Client Packages --

  Future<void> fetchClientPackages() async {
    state = state.copyWith(isLoadingPackages: true);

    try {
      final response = await _apiClient.get(
        ApiConstants.clientPackages(clientId),
      );

      final data = response['data'];
      final rawList = data is Map ? data['packages'] : data;

      final packages = _parseList<ClientPackage>(
        rawList,
        ClientPackage.fromJson,
      );

      state = state.copyWith(
        clientPackages: packages,
        isLoadingPackages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPackages: false,
      );
    }
  }

  // -- Request Check-In --

  Future<String?> requestCheckIn() async {
    try {
      await _apiClient.post(
        ApiConstants.clientRequestCheckIn(clientId),
      );
      return null;
    } catch (e) {
      return _extractErrorMessage(e);
    }
  }

  // -- Cancel Program --

  Future<String?> cancelProgram(String programId) async {
    try {
      await _apiClient.post(
        ApiConstants.clientCancelProgram(clientId, programId),
      );
      await fetchActiveProgram();
      return null;
    } catch (e) {
      return _extractErrorMessage(e);
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
