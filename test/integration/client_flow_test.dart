import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _testClientId = 'test-client-id';
const _testTimestamp = 1700000000000;

Map<String, dynamic> _clientJson({
  String id = _testClientId,
  String name = 'Test Client',
  String email = 'client@test.com',
}) => {
      'id': id,
      'name': name,
      'email': email,
      'status': 'active',
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

Map<String, dynamic> _measurementJson({String id = 'm-1'}) => {
      'id': id,
      'client_id': _testClientId,
      'measurement_date': _testTimestamp,
      'weight_kg': 80.0,
      'body_fat_percentage': 15.0,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

Map<String, dynamic> _photoJson({String id = 'p-1'}) => {
      'id': id,
      'client_id': _testClientId,
      'photo_date': _testTimestamp,
      'image_path': '/photos/test.jpg',
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  tearDown(() {
    container.dispose();
  });

  group('ClientListNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        clientListProvider.overrideWith(
          (ref) => ClientListNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has empty clients and is not loading', () {
      final state = container.read(clientListProvider);
      expect(state.clients, isEmpty);
      expect(state.filteredClients, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchClients populates the client list', () async {
      final clientListJson = [
        _clientJson(id: 'c-1'),
        _clientJson(id: 'c-2', name: 'Jane Doe', email: 'jane@test.com'),
      ];

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': clientListJson,
          });

      await container.read(clientListProvider.notifier).fetchClients();

      final state = container.read(clientListProvider);
      expect(state.clients, hasLength(2));
      expect(state.clients[0].id, 'c-1');
      expect(state.clients[1].name, 'Jane Doe');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchClients handles empty response', () async {
      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [],
          });

      await container.read(clientListProvider.notifier).fetchClients();

      final state = container.read(clientListProvider);
      expect(state.clients, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('setSearch filters clients by name', () async {
      // Pre-populate clients
      final notifier = container.read(clientListProvider.notifier);
      final clientListJson = [
        _clientJson(id: 'c-1', name: 'Alice Smith'),
        _clientJson(id: 'c-2', name: 'Bob Jones'),
        _clientJson(id: 'c-3', name: 'Charlie Brown'),
      ];

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': clientListJson,
          });

      await notifier.fetchClients();

      // Act: search
      notifier.setSearch('bob');

      // Assert
      final state = container.read(clientListProvider);
      expect(state.filteredClients, hasLength(1));
      expect(state.filteredClients.first.name, 'Bob Jones');
    });

    test('fetchClients sets error on failure', () async {
      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('API error'));

      await container.read(clientListProvider.notifier).fetchClients();

      final state = container.read(clientListProvider);
      expect(state.clients, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('ClientDetailNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        clientDetailProvider(_testClientId).overrideWith(
          (ref) => ClientDetailNotifier(
            apiClient: mockApiClient,
            clientId: _testClientId,
          ),
        ),
      ]);
    });

    test('fetchClient loads client details', () async {
      when(() => mockApiClient.get(
            '/clients/$_testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _clientJson(),
          });

      await container
          .read(clientDetailProvider(_testClientId).notifier)
          .fetchClient();

      final state = container.read(clientDetailProvider(_testClientId));
      expect(state.client, isNotNull);
      expect(state.client!.id, _testClientId);
      expect(state.client!.name, 'Test Client');
      expect(state.isLoadingClient, isFalse);
      expect(state.error, isNull);
    });

    test('fetchMeasurements loads measurements tab data', () async {
      when(() => mockApiClient.get(
            '/clients/$_testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [_measurementJson(id: 'm-1'), _measurementJson(id: 'm-2')],
          });

      await container
          .read(clientDetailProvider(_testClientId).notifier)
          .fetchMeasurements();

      final state = container.read(clientDetailProvider(_testClientId));
      expect(state.measurements, hasLength(2));
      expect(state.measurements[0].weightKg, 80.0);
      expect(state.isLoadingMeasurements, isFalse);
    });

    test('fetchPhotos loads photos tab data', () async {
      when(() => mockApiClient.get(
            '/clients/$_testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [_photoJson(id: 'p-1')],
          });

      await container
          .read(clientDetailProvider(_testClientId).notifier)
          .fetchPhotos();

      final state = container.read(clientDetailProvider(_testClientId));
      expect(state.photos, hasLength(1));
      expect(state.photos[0].imagePath, '/photos/test.jpg');
      expect(state.isLoadingPhotos, isFalse);
    });

    test('fetchAll loads client, measurements, and photos', () async {
      // Mock all four endpoints
      when(() => mockApiClient.get(
            '/clients/$_testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _clientJson(),
          });

      when(() => mockApiClient.get(
            '/clients/$_testClientId/measurements',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [_measurementJson()],
          });

      when(() => mockApiClient.get(
            '/clients/$_testClientId/photos',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [_photoJson()],
          });

      when(() => mockApiClient.get(
            '/clients/$_testClientId/sessions',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [],
          });

      await container
          .read(clientDetailProvider(_testClientId).notifier)
          .fetchAll();

      final state = container.read(clientDetailProvider(_testClientId));
      expect(state.client, isNotNull);
      expect(state.measurements, hasLength(1));
      expect(state.photos, hasLength(1));
      expect(state.isLoading, isFalse);
    });

    test('fetchClient sets error on API failure', () async {
      when(() => mockApiClient.get(
            '/clients/$_testClientId',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Not found'));

      await container
          .read(clientDetailProvider(_testClientId).notifier)
          .fetchClient();

      final state = container.read(clientDetailProvider(_testClientId));
      expect(state.client, isNull);
      expect(state.isLoadingClient, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
