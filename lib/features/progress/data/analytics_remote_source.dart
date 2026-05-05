import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_analytics.dart';

/// Provider for [AnalyticsRemoteSource] singleton.
final analyticsRemoteSourceProvider = Provider<AnalyticsRemoteSource>((ref) {
  return AnalyticsRemoteSource(apiClient: ApiClient.instance);
});

/// Remote data source for all analytics-related API calls.
///
/// All methods throw [ApiException] on failure.
class AnalyticsRemoteSource {
  final ApiClient _apiClient;

  AnalyticsRemoteSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /api/client/analytics?days=30
  /// Fetches analytics data including heatmap, volume history, muscle
  /// distribution, recent personal records, and consistency score.
  Future<ClientAnalytics> fetchAnalytics({int days = 30}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.clientAnalytics,
      queryParams: {'days': days},
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return ClientAnalytics.fromJson(data);
  }

  /// GET /api/client/progress
  /// Fetches progress data including weight, body fat, volume, exercise
  /// performance, favorite exercises, and worst performing exercises.
  Future<ClientProgress> fetchProgress() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.clientProgress,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return ClientProgress.fromJson(data);
  }
}
