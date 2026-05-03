import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _programJson({
  String id = 'prog-1',
  String name = 'Test Program',
  String? description = 'A test program description',
}) => {
      'id': id,
      'name': name,
      'description': ?description,
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

  group('Program Flow', () {
    setUp(() {
      container = createTestContainer(overrides: [
        programsProvider.overrideWith(
          (ref) => ProgramsNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has empty programs, not loading, no error', () {
      final state = container.read(programsProvider);
      expect(state.programs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchPrograms populates the programs list', () async {
      final programListJson = [
        _programJson(id: 'p1', name: 'Program One'),
        _programJson(id: 'p2', name: 'Program Two', description: 'Second program'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': programListJson,
          });

      await container.read(programsProvider.notifier).fetchPrograms();

      final state = container.read(programsProvider);
      expect(state.programs, hasLength(2));
      expect(state.programs[0].id, 'p1');
      expect(state.programs[0].name, 'Program One');
      expect(state.programs[1].name, 'Program Two');
      expect(state.programs[1].description, 'Second program');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('create program and verify it appears in the list', () async {
      // Mock the POST for createProgram
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _programJson(id: 'new-prog', name: 'New Program', description: 'Created in test'),
          });

      final notifier = container.read(programsProvider.notifier);

      // Act: create a program
      final created = await notifier.createProgram('New Program', 'Created in test');

      // Assert: program was created and returned
      expect(created, isNotNull);
      expect(created!.id, 'new-prog');
      expect(created.name, 'New Program');
      expect(created.description, 'Created in test');

      // Assert: program is in the state list
      final state = container.read(programsProvider);
      expect(state.programs, hasLength(1));
      expect(state.programs.first.id, 'new-prog');
      expect(state.programs.first.name, 'New Program');

      // Verify the API call was made correctly
      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
        body: {'name': 'New Program', 'description': 'Created in test'},
      )).called(1);
    });

    test('program detail can be found after fetch', () async {
      // Setup: fetch returns two programs
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              _programJson(id: 'detail-1', name: 'Detail Program'),
              _programJson(id: 'detail-2', name: 'Another Program'),
            ],
          });

      await container.read(programsProvider.notifier).fetchPrograms();

      // Act: find a specific program in the list
      final state = container.read(programsProvider);
      final detailProgram = state.programs.where((p) => p.id == 'detail-1').firstOrNull;

      // Assert
      expect(detailProgram, isNotNull);
      expect(detailProgram!.name, 'Detail Program');
      expect(detailProgram.description, 'A test program description');
    });

    test('fetchPrograms handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [],
          });

      await container.read(programsProvider.notifier).fetchPrograms();

      final state = container.read(programsProvider);
      expect(state.programs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchPrograms sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('API error'));

      await container.read(programsProvider.notifier).fetchPrograms();

      final state = container.read(programsProvider);
      expect(state.programs, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('create program with null description omits it from request body', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _programJson(id: 'minimal', name: 'Minimal', description: null),
          });

      await container.read(programsProvider.notifier).createProgram('Minimal', null);

      verify(() => mockApiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
        body: {'name': 'Minimal'},
      )).called(1);
    });
  });
}
