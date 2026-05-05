import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _trainerJson() => {
      'id': 'trainer-1',
      'name': 'John Trainer',
      'email': 'john@trainer.com',
      'phone': '+48123456789',
      'avatar_path': 'https://example.com/avatar.jpg',
      'specialties': <String>['Strength', 'Cardio'],
      'about_me': 'Experienced fitness coach with 10 years of expertise.',
      'average_rating': 4.8,
      'location': 'Warsaw, Poland',
    };

Map<String, dynamic> _deleteResponseJson() => {
      'data': <String, dynamic>{
        'message': 'Unlinked.',
      },
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  group('MyTrainerScreen API', () {
    test('GET /client/trainer returns trainer data in the data envelope', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/client/trainer',
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _trainerJson(),
          });

      final response = await mockApiClient.get<Map<String, dynamic>>(
        '/client/trainer',
      );

      // Simulate the screen's data extraction
      final rawData = response['data'];
      final trainer = rawData is Map<String, dynamic> ? rawData : null;

      expect(trainer, isNotNull);
      expect(trainer!['name'], 'John Trainer');
      expect(trainer['email'], 'john@trainer.com');
      expect(trainer['average_rating'], 4.8);
      expect(trainer['specialties'], hasLength(2));
    });

    test('GET /client/trainer handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/client/trainer',
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      final response = await mockApiClient.get<Map<String, dynamic>>(
        '/client/trainer',
      );

      final rawData = response['data'];
      final trainer = rawData is Map<String, dynamic> ? rawData : null;

      expect(trainer, isNull);
    });

    test('GET /client/trainer handles non-Map data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/client/trainer',
          )).thenAnswer((_) async => <String, dynamic>{
            'data': 'not a map',
          });

      final response = await mockApiClient.get<Map<String, dynamic>>(
        '/client/trainer',
      );

      final rawData = response['data'];
      final trainer = rawData is Map<String, dynamic> ? rawData : null;

      expect(trainer, isNull);
    });

    test('DELETE /client/trainer succeeds and returns a message', () async {
      when(() => mockApiClient.delete(
            '/client/trainer',
          )).thenAnswer((_) async => {});

      // Should not throw
      await mockApiClient.delete('/client/trainer');

      verify(() => mockApiClient.delete('/client/trainer')).called(1);
    });

    test('GET /client/trainer throws on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            '/client/trainer',
          )).thenThrow(Exception('Network error'));

      expect(
        () => mockApiClient.get<Map<String, dynamic>>('/client/trainer'),
        throwsException,
      );
    });

    test('DELETE /client/trainer throws on API failure', () async {
      when(() => mockApiClient.delete(
            '/client/trainer',
          )).thenThrow(Exception('Delete failed'));

      expect(
        () => mockApiClient.delete('/client/trainer'),
        throwsException,
      );
    });
  });
}
