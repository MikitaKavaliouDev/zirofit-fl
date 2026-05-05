import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _profileJson({
  String id = 'trainer-1',
  String userId = 'user-1',
}) => {
      'id': id,
      'user_id': userId,
      'certifications': null,
      'phone': '+48123456789',
      'about_me': 'Experienced fitness coach',
      'philosophy': null,
      'methodology': null,
      'branding': null,
      'banner_image_path': null,
      'custom_domain': null,
      'domain_verified': false,
      'profile_photo_path': null,
      'specialties': <String>['Strength', 'Cardio'],
      'training_types': <String>['IN_PERSON', 'ONLINE'],
      'business_currency': 'PLN',
      'average_rating': 4.5,
      'completion_percentage': 80,
      'missing_fields': null,
      'is_verified': true,
      'availability': null,
      'min_service_price': 100.0,
      'location': 'Warsaw',
      'location_normalized': null,
      'latitude': 52.23,
      'longitude': 21.01,
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
      exploreProvider.overrideWith(
        (ref) => ExploreNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ExploreNotifier', () {
    test('initial state has empty trainers, not loading, no error', () {
      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchFeatured populates the trainer list', () async {
      final trainerListJson = [
        _profileJson(id: 't-1', userId: 'u-1'),
        _profileJson(id: 't-2', userId: 'u-2'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': trainerListJson,
          });

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, hasLength(2));
      expect(state.trainers[0].id, 't-1');
      expect(state.trainers[0].location, 'Warsaw');
      expect(state.trainers[1].averageRating, 4.5);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchFeatured handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchFeatured handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchFeatured sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.exploreFeatured,
          )).thenThrow(Exception('API error'));

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('refresh calls fetchFeatured and populates trainers', () async {
      final trainerListJson = [
        _profileJson(id: 't-1'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': trainerListJson,
          });

      await container.read(exploreProvider.notifier).refresh();

      final state = container.read(exploreProvider);
      expect(state.trainers, hasLength(1));
      expect(state.trainers[0].id, 't-1');
      expect(state.isLoading, isFalse);
    });
  });
}
