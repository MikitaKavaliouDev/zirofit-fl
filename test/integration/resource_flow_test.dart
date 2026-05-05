import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/features/resources/providers/resource_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _resourceJson({
  String id = 'res-1',
  String title = 'Test Resource',
  String? description = 'A test resource',
}) => {
      'id': id,
      'trainer_id': 'trainer-1',
      'title': title,
      'description': description,
      'file_url': 'https://example.com/file.pdf',
      'file_type': 'PDF',
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
      'deleted_at': null,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      resourcesProvider.overrideWith(
        (ref) => ResourceNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ResourceNotifier', () {
    test('initial state has empty resources, not loading, no error', () {
      final state = container.read(resourcesProvider);
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNull);
    });

    test('fetchResources populates the resource list', () async {
      final resourceListJson = [
        _resourceJson(id: 'r-1', title: 'Resource One'),
        _resourceJson(id: 'r-2', title: 'Resource Two'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': resourceListJson,
          });

      await container.read(resourcesProvider.notifier).fetchResources();

      final state = container.read(resourcesProvider);
      expect(state.resources, hasLength(2));
      expect(state.resources[0].id, 'r-1');
      expect(state.resources[0].title, 'Resource One');
      expect(state.resources[1].title, 'Resource Two');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchResources handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(resourcesProvider.notifier).fetchResources();

      final state = container.read(resourcesProvider);
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchResources handles non-list data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{'resources': <dynamic>[]},
          });

      await container.read(resourcesProvider.notifier).fetchResources();

      final state = container.read(resourcesProvider);
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchResources sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
          )).thenThrow(Exception('API error'));

      await container.read(resourcesProvider.notifier).fetchResources();

      final state = container.read(resourcesProvider);
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('createResource adds resource to state and returns it', () async {
      final newResourceJson = _resourceJson(
        id: 'r-new',
        title: 'New Resource',
      );

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': newResourceJson,
          });

      final created = await container
          .read(resourcesProvider.notifier)
          .createResource({'title': 'New Resource', 'file_url': 'https://example.com/doc.pdf', 'file_type': 'PDF'});

      expect(created.id, 'r-new');
      expect(created.title, 'New Resource');

      final state = container.read(resourcesProvider);
      expect(state.resources, hasLength(1));
      expect(state.resources.first.id, 'r-new');
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNotNull);
    });

    test('createResource sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenThrow(Exception('Create failed'));

      expect(
        () => container
            .read(resourcesProvider.notifier)
            .createResource({'title': 'Fail'}),
        throwsException,
      );

      final state = container.read(resourcesProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNotNull);
    });

    test('deleteResource removes resource from state', () async {
      // Pre-populate
      final resourceJson = _resourceJson(id: 'r-1');
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [resourceJson],
          });

      await container.read(resourcesProvider.notifier).fetchResources();
      expect(container.read(resourcesProvider).resources, hasLength(1));

      // Mock the delete
      when(() => mockApiClient.delete(
            ApiConstants.trainerResource('r-1'),
          )).thenAnswer((_) async => {});

      await container.read(resourcesProvider.notifier).deleteResource('r-1');

      final state = container.read(resourcesProvider);
      expect(state.resources, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, isNotNull);
    });

    test('deleteResource sets error on API failure', () async {
      when(() => mockApiClient.delete(
            ApiConstants.trainerResource('r-1'),
          )).thenThrow(Exception('Delete failed'));

      await container.read(resourcesProvider.notifier).deleteResource('r-1');

      final state = container.read(resourcesProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('clearSuccessMessage clears the success message', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerResourceVault,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _resourceJson(),
          });

      await container
          .read(resourcesProvider.notifier)
          .createResource({'title': 'Test'});
      expect(container.read(resourcesProvider).successMessage, isNotNull);

      container.read(resourcesProvider.notifier).clearSuccessMessage();

      expect(container.read(resourcesProvider).successMessage, isNull);
    });
  });
}
