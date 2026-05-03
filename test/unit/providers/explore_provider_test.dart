import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ExploreNotifier', () {
    test('initial state is correct', () {
      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchFeatured loads trainers on success', () async {
      final trainersJson = [
        {
          'id': 'trainer-1',
          'user_id': 'user-1',
          'about_me': 'John Doe',
          'specialties': ['Yoga', 'Pilates'],
          'average_rating': 4.5,
          'location': 'New York',
          'profile_photo_path': 'https://example.com/photo1.jpg',
          'business_currency': 'PLN',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
        {
          'id': 'trainer-2',
          'user_id': 'user-2',
          'about_me': 'Jane Smith',
          'specialties': ['HIIT', 'Strength Training'],
          'average_rating': 4.8,
          'location': 'Los Angeles',
          'business_currency': 'PLN',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => {
            'data': trainersJson,
          });

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, hasLength(2));
      expect(state.trainers[0].aboutMe, 'John Doe');
      expect(state.trainers[1].aboutMe, 'Jane Smith');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchFeatured sets error on failure', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exploreFeatured,
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.exploreFeatured),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.exploreFeatured),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('refresh calls fetchFeatured', () async {
      final trainersJson = [
        {
          'id': 'trainer-1',
          'user_id': 'user-1',
          'about_me': 'John Doe',
          'specialties': ['Yoga'],
          'business_currency': 'PLN',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      ];

      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => {
            'data': trainersJson,
          });

      await container.read(exploreProvider.notifier).refresh();

      final state = container.read(exploreProvider);
      expect(state.trainers, hasLength(1));
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('handles empty data response', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => {
            'data': [],
          });

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('handles missing data key gracefully', () async {
      when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
            ApiConstants.exploreFeatured,
          )).thenAnswer((_) async => {});

      await container.read(exploreProvider.notifier).fetchFeatured();

      final state = container.read(exploreProvider);
      expect(state.trainers, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });
}
