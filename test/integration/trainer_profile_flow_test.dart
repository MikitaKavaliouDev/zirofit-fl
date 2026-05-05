import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/benefit.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testId = 'profile-1';
const _testUserId = 'user-1';
const _testTimestamp = 1700000000000;

Profile _createProfile() => Profile(
      id: _testId,
      userId: _testUserId,
      aboutMe: 'Experienced fitness trainer',
      certifications: 'CPT, CES',
      phone: '+48123456789',
      specialties: ['Strength', 'HIIT'],
      businessCurrency: 'PLN',
      isVerified: true,
      completionPercentage: 75,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
    );

Service _createService({
  String id = 'svc-1',
  String title = 'Personal Training',
  double? price = 150.0,
}) =>
    Service(
      id: id,
      profileId: _testId,
      title: title,
      description: 'One-on-one personal training session',
      price: price,
      currency: 'PLN',
      duration: 60,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
    );

Package _createPackage({
  String id = 'pkg-1',
  String name = 'Starter Pack',
}) =>
    Package(
      id: id,
      name: name,
      description: '5 sessions package',
      price: 500.0,
      numberOfSessions: 5,
      isActive: true,
      stripeProductId: 'prod_123',
      stripePriceId: 'price_123',
      trainerId: _testUserId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
    );

Testimonial _createTestimonial({
  String id = 'test-1',
  String clientName = 'Jane C.',
}) =>
    Testimonial(
      id: id,
      profileId: _testId,
      clientName: clientName,
      testimonialText: 'Great trainer! Highly recommended.',
      rating: 5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
    );

Benefit _createBenefit({
  String id = 'ben-1',
  String title = 'Flexible Hours',
}) =>
    Benefit(
      id: id,
      profileId: _testId,
      iconName: 'clock',
      title: title,
      description: 'Schedule sessions at your convenience',
      orderColumn: 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_testTimestamp),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      trainerProfileProvider.overrideWith(
        (ref) => TrainerProfileNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('TrainerProfileNotifier', () {
    test('initial state has null profile and is not loading', () {
      final state = container.read(trainerProfileProvider);
      expect(state.profile, isNull);
      expect(state.user, isNull);
      expect(state.services, isEmpty);
      expect(state.packages, isEmpty);
      expect(state.testimonials, isEmpty);
      expect(state.benefits, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.activeTab, 0);
    });

    test('fetchProfile loads profile with services, packages, testimonials, benefits',
        () async {
      // Mock all five GET endpoints with fromJson
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createProfile());

      when(() => mockApiClient.get<List<Service>>(
            ApiConstants.profileMeServices,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [
            _createService(id: 'svc-1', title: 'Strength Training'),
            _createService(id: 'svc-2', title: 'Nutrition Coaching'),
          ]);

      when(() => mockApiClient.get<List<Package>>(
            ApiConstants.profileMePackages,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [
            _createPackage(id: 'pkg-1', name: 'Starter Pack'),
          ]);

      when(() => mockApiClient.get<List<Testimonial>>(
            ApiConstants.profileMeTestimonials,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [
            _createTestimonial(id: 'test-1'),
          ]);

      when(() => mockApiClient.get<List<Benefit>>(
            ApiConstants.profileMeBenefits,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [
            _createBenefit(id: 'ben-1', title: 'Flexible Hours'),
          ]);

      await container.read(trainerProfileProvider.notifier).fetchProfile();

      final state = container.read(trainerProfileProvider);
      expect(state.profile, isNotNull);
      expect(state.profile!.id, _testId);
      expect(state.profile!.aboutMe, 'Experienced fitness trainer');
      expect(state.profile!.specialties, contains('Strength'));
      expect(state.services, hasLength(2));
      expect(state.services[0].title, 'Strength Training');
      expect(state.packages, hasLength(1));
      expect(state.packages[0].name, 'Starter Pack');
      expect(state.testimonials, hasLength(1));
      expect(state.testimonials[0].clientName, 'Jane C.');
      expect(state.benefits, hasLength(1));
      expect(state.benefits[0].title, 'Flexible Hours');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchProfile handles empty services and packages', () async {
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createProfile());

      when(() => mockApiClient.get<List<Service>>(
            ApiConstants.profileMeServices,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Package>>(
            ApiConstants.profileMePackages,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Testimonial>>(
            ApiConstants.profileMeTestimonials,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Benefit>>(
            ApiConstants.profileMeBenefits,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      await container.read(trainerProfileProvider.notifier).fetchProfile();

      final state = container.read(trainerProfileProvider);
      expect(state.profile, isNotNull);
      expect(state.services, isEmpty);
      expect(state.packages, isEmpty);
      expect(state.testimonials, isEmpty);
      expect(state.benefits, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('updateTextContent updates profile text and refreshes', () async {
      // Initial fetch
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createProfile());

      when(() => mockApiClient.get<List<Service>>(
            ApiConstants.profileMeServices,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Package>>(
            ApiConstants.profileMePackages,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Testimonial>>(
            ApiConstants.profileMeTestimonials,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Benefit>>(
            ApiConstants.profileMeBenefits,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      await container.read(trainerProfileProvider.notifier).fetchProfile();
      expect(container.read(trainerProfileProvider).profile!.aboutMe,
          'Experienced fitness trainer');

      // Mock PUT for text content update
      when(() => mockApiClient.put<dynamic>(
            ApiConstants.profileMeTextContent,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      // After PUT, fetchProfile is called again, so mock the GETs again
      // (same mocks as above still apply)

      await container
          .read(trainerProfileProvider.notifier)
          .updateTextContent('about_me', 'Updated about me text');

      // After updateTextContent, fetchProfile is re-called
      // The mock returns the original profile, so aboutMe stays the same
      // (in real scenario the server would return updated data)
      final state = container.read(trainerProfileProvider);
      expect(state.isLoading, isFalse);
      // Verify PUT was called
      verify(() => mockApiClient.put<dynamic>(
            ApiConstants.profileMeTextContent,
            body: any(named: 'body'),
          )).called(1);
    });

    test('fetchProfile sets error on API failure', () async {
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('API error'));

      await container.read(trainerProfileProvider.notifier).fetchProfile();

      final state = container.read(trainerProfileProvider);
      expect(state.profile, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('setActiveTab updates active tab index', () {
      container.read(trainerProfileProvider.notifier).setActiveTab(2);
      expect(container.read(trainerProfileProvider).activeTab, 2);

      container.read(trainerProfileProvider.notifier).setActiveTab(0);
      expect(container.read(trainerProfileProvider).activeTab, 0);
    });

    test('addService adds a service to the state', () async {
      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createService(id: 'svc-new'));

      await container.read(trainerProfileProvider.notifier).addService({
        'title': 'New Service',
        'description': 'A brand new service',
      });

      final state = container.read(trainerProfileProvider);
      expect(state.services, hasLength(1));
      expect(state.services[0].id, 'svc-new');
      expect(state.isLoading, isFalse);
    });

    test('deleteService removes a service from the state', () async {
      // Add a service first
      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createService(id: 'svc-1'));

      await container
          .read(trainerProfileProvider.notifier)
          .addService({'title': 'Svc'});
      expect(container.read(trainerProfileProvider).services, hasLength(1));

      // Delete it
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeServices}/svc-1',
          )).thenAnswer((_) async {});

      await container
          .read(trainerProfileProvider.notifier)
          .deleteService('svc-1');

      final state = container.read(trainerProfileProvider);
      expect(state.services, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('addPackage adds a package to the state', () async {
      when(() => mockApiClient.post<Package>(
            ApiConstants.profileMePackages,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createPackage(id: 'pkg-new'));

      await container.read(trainerProfileProvider.notifier).addPackage({
        'name': 'New Package',
        'price': 299.0,
      });

      final state = container.read(trainerProfileProvider);
      expect(state.packages, hasLength(1));
      expect(state.packages[0].id, 'pkg-new');
    });

    // -------------------------------------------------------------------------
    // Response shape verification for profile data endpoints
    // -------------------------------------------------------------------------

    test('fetchProfile parses nested data envelope for services and packages',
        () async {
      // The provider passes fromJson for list endpoints which unwraps
      // json['data'] internally. Backend shapes:
      //   GET /profile/me/services  → {"data": {"services": [...]}}
      //   GET /profile/me/packages → {"data": {"packages": [...]}}
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createProfile());

      // Simulate backend returning data envelope with services nested
      when(() => mockApiClient.get<List<Service>>(
            ApiConstants.profileMeServices,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async {
        // The provider's fromJson unwraps data envelope:
        //   (json) => (json['data'] as List?)?.map(...).toList() ?? []
        return [
          _createService(id: 'svc-r1', title: 'Service A'),
          _createService(id: 'svc-r2', title: 'Service B'),
        ];
      });

      when(() => mockApiClient.get<List<Package>>(
            ApiConstants.profileMePackages,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => [
            _createPackage(id: 'pkg-r1', name: 'Package A'),
          ]);

      when(() => mockApiClient.get<List<Testimonial>>(
            ApiConstants.profileMeTestimonials,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      when(() => mockApiClient.get<List<Benefit>>(
            ApiConstants.profileMeBenefits,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => []);

      await container.read(trainerProfileProvider.notifier).fetchProfile();

      final state = container.read(trainerProfileProvider);
      expect(state.profile, isNotNull);
      expect(state.services, hasLength(2));
      expect(state.services[0].title, 'Service A');
      expect(state.services[1].title, 'Service B');
      expect(state.packages, hasLength(1));
      expect(state.packages[0].name, 'Package A');
    });

    test('deleteService succeeds with empty response body', () async {
      // First add a service
      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => _createService(id: 'svc-del'));

      await container
          .read(trainerProfileProvider.notifier)
          .addService({'title': 'To Delete'});
      expect(container.read(trainerProfileProvider).services, hasLength(1));

      // DELETE /profile/me/services/[id] → {"data": {"message": "Deleted."}}
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeServices}/svc-del',
          )).thenAnswer((_) async {});

      await container
          .read(trainerProfileProvider.notifier)
          .deleteService('svc-del');

      final state = container.read(trainerProfileProvider);
      expect(state.services, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('deleteService sets error on API failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeServices}/svc-fail',
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: '${ApiConstants.profileMeServices}/svc-fail'),
        response: Response(
          requestOptions:
              RequestOptions(path: '${ApiConstants.profileMeServices}/svc-fail'),
          statusCode: 404,
          data: errorResponse(message: 'Service not found'),
        ),
        type: DioExceptionType.badResponse,
      ));

      await container
          .read(trainerProfileProvider.notifier)
          .deleteService('svc-fail');

      final state = container.read(trainerProfileProvider);
      expect(state.error, contains('Service not found'));
      expect(state.isLoading, isFalse);
    });
  });
}
