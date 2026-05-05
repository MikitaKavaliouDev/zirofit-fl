import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/domain_provider.dart';
import 'package:zirofit_fl/features/settings/providers/settings_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

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

  // ---------------------------------------------------------------------------
  // SettingsNotifier
  // ---------------------------------------------------------------------------

  group('SettingsNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has defaults', () {
      final state = container.read(settingsProvider);
      expect(state.defaultCheckInDay, 0);
      expect(state.defaultCheckInHour, 9);
      expect(state.weightUnit, 'KG');
      expect(state.isLoading, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('loadSettings extracts fields from data envelope', () async {
      // Backend shape: GET /profile/me → {"data": {profile with settings fields}}
      final responseBody = dataResponse({
        'id': 'profile-1',
        'user_id': 'user-1',
        'about_me': 'Trainer bio',
        'defaultCheckInDay': 1, // Monday
        'defaultCheckInHour': 10,
        'weightUnit': 'LB',
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      });

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.profileMe,
          )).thenAnswer((_) async => responseBody);

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      expect(state.defaultCheckInDay, 1);
      expect(state.defaultCheckInHour, 10);
      expect(state.weightUnit, 'LB');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('loadSettings uses defaults when fields are missing', () async {
      // Backend returns profile data without settings fields
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.profileMe,
          )).thenAnswer((_) async => dataResponse({
            'id': 'profile-1',
            'user_id': 'user-1',
          }));

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      expect(state.defaultCheckInDay, 0);
      expect(state.defaultCheckInHour, 9);
      expect(state.weightUnit, 'KG');
      expect(state.isLoading, isFalse);
    });

    test('loadSettings handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.profileMe,
          )).thenAnswer((_) async => <String, dynamic>{});

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      // Falls back to defaults when response.data is null
      expect(state.defaultCheckInDay, 0);
      expect(state.defaultCheckInHour, 9);
      expect(state.isLoading, isFalse);
    });

    test('loadSettings sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.profileMe,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.profileMe),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.profileMe),
          statusCode: 401,
          data: errorResponse(message: 'Unauthorized'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container.read(settingsProvider.notifier).loadSettings();

      final state = container.read(settingsProvider);
      expect(state.error, contains('Unauthorized'));
      expect(state.isLoading, isFalse);
    });

    test('saveCheckInDefaults sends PUT and sets success message', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({'message': 'Updated.'}));

      await container
          .read(settingsProvider.notifier)
          .saveCheckInDefaults(2, 14);

      final state = container.read(settingsProvider);
      expect(state.defaultCheckInDay, 2);
      expect(state.defaultCheckInHour, 14);
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNotNull);
      expect(state.error, isNull);

      verify(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: {'defaultCheckInDay': 2, 'defaultCheckInHour': 14},
          )).called(1);
    });

    test('saveCheckInDefaults sets error on failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerSettings),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerSettings),
          statusCode: 400,
          data: errorResponse(message: 'Bad request'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container
          .read(settingsProvider.notifier)
          .saveCheckInDefaults(0, 9);

      final state = container.read(settingsProvider);
      expect(state.error, contains('Bad request'));
      expect(state.isSaving, isFalse);
    });

    test('toggleWeightUnit sends PUT and sets success message', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({'message': 'Updated.'}));

      await container
          .read(settingsProvider.notifier)
          .toggleWeightUnit('LB');

      final state = container.read(settingsProvider);
      expect(state.weightUnit, 'LB');
      expect(state.isSaving, isFalse);
      expect(state.successMessage, contains('LB'));

      verify(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: {'weightUnit': 'LB'},
          )).called(1);
    });

    test('toggleWeightUnit sets error on failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerSettings,
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      await container
          .read(settingsProvider.notifier)
          .toggleWeightUnit('LB');

      final state = container.read(settingsProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // DomainNotifier
  // ---------------------------------------------------------------------------

  group('DomainNotifier', () {
    setUp(() {
      container = createTestContainer(overrides: [
        domainProvider.overrideWith(
          (ref) => DomainNotifier(apiClient: mockApiClient),
        ),
      ]);
    });

    test('initial state has null domain and is not loading', () {
      final state = container.read(domainProvider);
      expect(state.domain, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isAdding, isFalse);
      expect(state.isVerified, isFalse);
      expect(state.error, isNull);
    });

    test('addDomain parses data envelope correctly', () async {
      // Backend shape: POST /domain/add → jsonSuccess({ domain, verified })
      // → {"data": {"domain": "example.com", "verified": false}}
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({
            'domain': 'example.com',
            'verified': false,
          }));

      final success =
          await container.read(domainProvider.notifier).addDomain('example.com');

      expect(success, isTrue);
      final state = container.read(domainProvider);
      expect(state.domain, 'example.com');
      expect(state.isVerified, isFalse);
      expect(state.isAdding, isFalse);
      expect(state.error, isNull);
    });

    test('addDomain marks verified when backend returns verified=true', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({
            'domain': 'verified.com',
            'verified': true,
          }));

      await container
          .read(domainProvider.notifier)
          .addDomain('verified.com');

      final state = container.read(domainProvider);
      expect(state.domain, 'verified.com');
      expect(state.isVerified, isTrue);
    });

    test('addDomain handles non-map data gracefully', () async {
      // Backend returns data that's not a map
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{'data': 'just a string'});

      final success =
          await container.read(domainProvider.notifier).addDomain('example.com');

      expect(success, isTrue);
      final state = container.read(domainProvider);
      expect(state.domain, 'example.com');
      expect(state.isVerified, isFalse);
    });

    test('addDomain sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.domainAdd),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.domainAdd),
          statusCode: 409,
          data: errorResponse(message: 'Domain already taken'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final success =
          await container.read(domainProvider.notifier).addDomain('taken.com');

      expect(success, isFalse);
      final state = container.read(domainProvider);
      expect(state.error, contains('Domain already taken'));
      expect(state.isAdding, isFalse);
    });

    test('verifyDomain parses verified from data envelope', () async {
      // Backend shape: POST /domain/verify → {"data": {"verified": true}}
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => dataResponse({'verified': true}));

      final verified =
          await container.read(domainProvider.notifier).verifyDomain();

      expect(verified, isTrue);
      final state = container.read(domainProvider);
      expect(state.isVerified, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('verifyDomain handles false response', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenAnswer((_) async => dataResponse({'verified': false}));

      final verified =
          await container.read(domainProvider.notifier).verifyDomain();

      expect(verified, isFalse);
      final state = container.read(domainProvider);
      expect(state.isVerified, isFalse);
    });

    test('verifyDomain sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainVerify,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.domainVerify),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.domainVerify),
          statusCode: 500,
          data: errorResponse(message: 'Verification failed'),
        ),
        type: DioExceptionType.badResponse,
      ));

      final verified =
          await container.read(domainProvider.notifier).verifyDomain();

      expect(verified, isFalse);
      final state = container.read(domainProvider);
      expect(state.error, contains('Verification failed'));
      expect(state.isLoading, isFalse);
    });

    test('reset clears domain state', () async {
      // First add a domain
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.domainAdd,
            body: any(named: 'body'),
          )).thenAnswer((_) async => dataResponse({
            'domain': 'example.com',
            'verified': true,
          }));

      await container
          .read(domainProvider.notifier)
          .addDomain('example.com');
      expect(container.read(domainProvider).domain, isNotNull);

      // Reset
      container.read(domainProvider.notifier).reset();

      final state = container.read(domainProvider);
      expect(state.domain, isNull);
      expect(state.isVerified, isFalse);
      expect(state.isAdding, isFalse);
      expect(state.isLoading, isFalse);
    });
  });
}
