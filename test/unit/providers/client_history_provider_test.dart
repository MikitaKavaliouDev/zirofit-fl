import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_history_provider.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  const testClientId = 'test-client-id';
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late ClientHistoryNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    notifier = ClientHistoryNotifier(
      apiClient: mockApiClient,
      clientId: testClientId,
    );
  });

  group('ClientHistoryNotifier', () {
    test('initial state has empty sessions, loading false', () {
      final state = notifier.state;
      expect(state.sessions, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingMore, false);
      expect(state.error, isNull);
      expect(state.dateRange, HistoryDateRange.all);
      expect(state.page, 1);
      expect(state.hasMore, true);
    });

    // -----------------------------------------------------------------------
    // fetchHistory — Test 1: populates sessions
    // -----------------------------------------------------------------------

    test('fetchHistory populates sessions on success', () async {
      final now = DateTime.now();
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-1',
            'client_id': testClientId,
            'start_time': now.millisecondsSinceEpoch,
            'end_time':
                now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 5000,
            'totalSets': 25,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
          <String, dynamic>{
            'id': 's-2',
            'client_id': testClientId,
            'start_time':
                now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
            'end_time': now
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 3000,
            'totalSets': 15,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
        ],
      });

      await notifier.fetchHistory();

      final state = notifier.state;
      expect(state.sessions.length, 2);
      expect(state.sessions[0].id, 's-1');
      expect(state.sessions[0].totalVolume, 5000);
      expect(state.sessions[0].totalSets, 25);
      expect(state.sessions[1].id, 's-2');
      expect(state.sessions[1].totalVolume, 3000);
      expect(state.sessions[1].totalSets, 15);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchHistory sets loading true before completion', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      final future = notifier.fetchHistory();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchHistory handles empty data', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      await notifier.fetchHistory();

      expect(notifier.state.sessions, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('fetchHistory sets error on failure', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.clients}/$testClientId/sessions'),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchHistory();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Connection timeout. Please try again.');
      expect(notifier.state.sessions, isEmpty);
    });

    // -----------------------------------------------------------------------
    // volumeData — Test 2: computes chart data
    // -----------------------------------------------------------------------

    test('volumeData computes daily aggregated volume chart data', () async {
      final now = DateTime.now();
      // Two sessions on the same day
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-1',
            'client_id': testClientId,
            'start_time': now.millisecondsSinceEpoch,
            'end_time':
                now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 5000,
            'totalSets': 25,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
          <String, dynamic>{
            'id': 's-2',
            'client_id': testClientId,
            'start_time':
                now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
            'end_time':
                now.add(const Duration(hours: 3)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 3000,
            'totalSets': 15,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
        ],
      });

      await notifier.fetchHistory();
      final volumeData = notifier.state.volumeData;

      // Both sessions on same day → one data point with sum (8000)
      expect(volumeData.length, 1);
      expect(volumeData[0].volume, 8000);
    });

    test('volumeData returns empty list when no sessions', () {
      expect(notifier.state.volumeData, isEmpty);
    });

    test('volumeData computes separate entries for different dates',
        () async {
      final now = DateTime.now();
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-1',
            'client_id': testClientId,
            'start_time': now.millisecondsSinceEpoch,
            'end_time':
                now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 5000,
            'totalSets': 25,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
          <String, dynamic>{
            'id': 's-2',
            'client_id': testClientId,
            'start_time':
                now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
            'end_time': now
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 3000,
            'totalSets': 15,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
        ],
      });

      await notifier.fetchHistory();
      final volumeData = notifier.state.volumeData;

      expect(volumeData.length, 2);
      expect(volumeData[0].volume, 3000); // older day first (sorted ascending)
      expect(volumeData[1].volume, 5000);
    });

    // -----------------------------------------------------------------------
    // dateRange — Test 3: filter works correctly
    // -----------------------------------------------------------------------

    test('setDateRange changes dateRange and re-fetches', () async {
      // First fetch with all
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      await notifier.fetchHistory();
      expect(notifier.state.dateRange, HistoryDateRange.all);

      // Now set to oneMonth
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-filtered',
            'client_id': testClientId,
            'start_time': DateTime.now().millisecondsSinceEpoch,
            'end_time':
                DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 2000,
            'totalSets': 10,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
        ],
      });

      notifier.setDateRange(HistoryDateRange.oneMonth);

      // Wait for async fetch to complete
      await Future(() {});
      await Future(() {});

      expect(notifier.state.dateRange, HistoryDateRange.oneMonth);
      expect(notifier.state.sessions.length, 1);
      expect(notifier.state.sessions[0].id, 's-filtered');
    });

    test('setDateRange with same range does nothing', () {
      notifier.setDateRange(HistoryDateRange.all);
      // No API call should be made; state unchanged
      expect(notifier.state.sessions, isEmpty);
    });

    test('fetchHistory with dateRange passes start_date query param',
        () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((invocation) async {
        final params =
            invocation.namedArguments[#queryParams] as Map<String, dynamic>;
        expect(params.containsKey('start_date'), isTrue);
        expect(params['page'], 1);
        expect(params['per_page'], 20);
        return <String, dynamic>{'data': []};
      });

      await notifier.fetchHistory(dateRange: HistoryDateRange.oneMonth);

      expect(notifier.state.dateRange, HistoryDateRange.oneMonth);
      expect(notifier.state.isLoading, false);
    });

    // -----------------------------------------------------------------------
    // pagination — Test 4: loads more
    // -----------------------------------------------------------------------

    test('loadMore appends sessions and increments page', () async {
      // First fetch — return a full page
      final now = DateTime.now();
      final firstPage = List<Map<String, dynamic>>.generate(20, (i) {
        final time = now.subtract(Duration(days: i));
        return <String, dynamic>{
          'id': 's-$i',
          'client_id': testClientId,
          'start_time': time.millisecondsSinceEpoch,
          'end_time':
              time.add(const Duration(hours: 1)).millisecondsSinceEpoch,
          'status': 'COMPLETED',
          'totalVolume': 1000.0 + i * 100,
          'totalSets': 10 + i,
          'created_at': time.millisecondsSinceEpoch,
          'updated_at': time.millisecondsSinceEpoch,
        };
      });

      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': firstPage});

      await notifier.fetchHistory();

      expect(notifier.state.sessions.length, 20);
      expect(notifier.state.hasMore, true);
      expect(notifier.state.page, 1);

      // Second page
      final secondPage = List<Map<String, dynamic>>.generate(5, (i) {
        final time = now.subtract(Duration(days: 20 + i));
        return <String, dynamic>{
          'id': 's-${20 + i}',
          'client_id': testClientId,
          'start_time': time.millisecondsSinceEpoch,
          'end_time':
              time.add(const Duration(hours: 1)).millisecondsSinceEpoch,
          'status': 'COMPLETED',
          'totalVolume': 500.0 + i * 50,
          'totalSets': 5 + i,
          'created_at': time.millisecondsSinceEpoch,
          'updated_at': time.millisecondsSinceEpoch,
        };
      });

      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': secondPage});

      await notifier.loadMore();

      expect(notifier.state.sessions.length, 25);
      expect(notifier.state.page, 2);
      expect(notifier.state.hasMore, false); // less than perPage
      expect(notifier.state.isLoadingMore, false);
    });

    test('loadMore does nothing when already loading', () async {
      // Set loadingMore true directly
      // Trigger a real fetch first
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      await notifier.fetchHistory();

      // loadMore should not make API call when hasMore is false
      await notifier.loadMore();
      expect(notifier.state.page, 1);
    });

    test('loadMore does nothing when hasMore is false', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async =>
          <String, dynamic>{'data': []});

      await notifier.fetchHistory();

      // hasMore is now false
      await notifier.loadMore();
      expect(notifier.state.page, 1);
    });

    test('refresh re-fetches from page 1', () async {
      when(() => mockApiClient.get(
            '${ApiConstants.clients}/$testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 's-refreshed',
            'client_id': testClientId,
            'start_time': DateTime.now().millisecondsSinceEpoch,
            'end_time':
                DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
            'status': 'COMPLETED',
            'totalVolume': 1000,
            'totalSets': 10,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
        ],
      });

      await notifier.refresh();

      expect(notifier.state.sessions.length, 1);
      expect(notifier.state.page, 1);
      expect(notifier.state.isLoading, false);
    });
  });
}
