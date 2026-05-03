import 'package:dio/dio.dart';

import 'sync_models.dart';

/// Remote data source for sync operations.
/// Communicates with the backend sync API (pull/push endpoints).
class SyncRemoteSource {
  final Dio _dio;

  SyncRemoteSource(this._dio);

  /// Pull all changes since [lastPulledAt] from the server.
  Future<SyncPayload> pull(int lastPulledAt) async {
    final response = await _dio.get(
      '/sync/pull',
      queryParameters: {'last_pulled_at': lastPulledAt},
    );

    final data = response.data as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>? ?? data;

    return SyncPayload.fromJson(payload);
  }

  /// Push local changes to the server.
  Future<Map<String, dynamic>> push(
      Map<String, dynamic> changes) async {
    final response = await _dio.post(
      '/sync/push',
      data: {'changes': changes},
    );

    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>? ?? data;
  }
}
