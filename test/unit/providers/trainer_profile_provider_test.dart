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

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerProfileNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerProfileNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Profile createProfile() => Profile(
        id: 'prof-1',
        userId: 'user-1',
        aboutMe: 'About me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  Service createService() => Service(
        id: 'svc-1',
        profileId: 'prof-1',
        title: 'Online Coaching',
        description: 'Full coaching plan',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  Package createPackage() => Package(
        id: 'pkg-1',
        name: 'Starter Pack',
        price: 99.0,
        numberOfSessions: 8,
        stripeProductId: 'prod_1',
        stripePriceId: 'price_1',
        trainerId: 'user-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  Testimonial createTestimonial() => Testimonial(
        id: 'test-1',
        profileId: 'prof-1',
        clientName: 'John',
        testimonialText: 'Great trainer!',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  Benefit createBenefit() => Benefit(
        id: 'ben-1',
        profileId: 'prof-1',
        title: 'Flexible hours',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  /// Stubs all five GET endpoints needed for `fetchProfile` to succeed.
  void stubFetchProfileSuccess({
    Profile? profile,
    List<Service>? services,
    List<Package>? packages,
    List<Testimonial>? testimonials,
    List<Benefit>? benefits,
  }) {
    final p = profile ?? createProfile();
    final s = services ?? [createService()];
    final pk = packages ?? [createPackage()];
    final t = testimonials ?? [createTestimonial()];
    final b = benefits ?? [createBenefit()];

    when(() => mockApiClient.get<Profile>(
          ApiConstants.profileMe,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => p);

    when(() => mockApiClient.get<List<Service>>(
          ApiConstants.profileMeServices,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => s);

    when(() => mockApiClient.get<List<Package>>(
          ApiConstants.profileMePackages,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => pk);

    when(() => mockApiClient.get<List<Testimonial>>(
          ApiConstants.profileMeTestimonials,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => t);

    when(() => mockApiClient.get<List<Benefit>>(
          ApiConstants.profileMeBenefits,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => b);
  }

  group('TrainerProfileNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has loading false and empty collections', () {
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.services, isEmpty);
      expect(notifier.state.packages, isEmpty);
      expect(notifier.state.testimonials, isEmpty);
      expect(notifier.state.benefits, isEmpty);
      expect(notifier.state.profile, isNull);
      expect(notifier.state.user, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchProfile – success
    // ---------------------------------------------------------------------------
    test('fetchProfile populates all sections on success', () async {
      stubFetchProfileSuccess();

      await notifier.fetchProfile();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.profile, isNotNull);
      expect(notifier.state.profile!.id, 'prof-1');
      expect(notifier.state.services.length, 1);
      expect(notifier.state.packages.length, 1);
      expect(notifier.state.testimonials.length, 1);
      expect(notifier.state.benefits.length, 1);
    });

    // ---------------------------------------------------------------------------
    // fetchProfile – failure
    // ---------------------------------------------------------------------------
    test('fetchProfile sets error on failure', () async {
      when(() => mockApiClient.get<Profile>(
            ApiConstants.profileMe,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Server error'));

      await notifier.fetchProfile();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // updateTextContent
    // ---------------------------------------------------------------------------
    test('updateTextContent updates the text section and refreshes profile',
        () async {
      when(() => mockApiClient.put(
            ApiConstants.profileMeTextContent,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {});

      // fetchProfile will be called after the PUT
      stubFetchProfileSuccess();

      await notifier.updateTextContent('about_me', 'New about me');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.profile, isNotNull);
      verify(() => mockApiClient.put(
            ApiConstants.profileMeTextContent,
            body: any(named: 'body'),
          )).called(1);
    });

    test('updateTextContent sets error on failure', () async {
      when(() => mockApiClient.put(
            ApiConstants.profileMeTextContent,
            body: any(named: 'body'),
          )).thenThrow(Exception('Update failed'));

      await notifier.updateTextContent('about_me', 'New about me');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // addService
    // ---------------------------------------------------------------------------
    test('addService appends service', () async {
      final service = createService();

      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => service);

      await notifier.addService({'title': 'New Service', 'description': 'Desc'});

      expect(notifier.state.services.length, 1);
      expect(notifier.state.services.first.id, 'svc-1');
      expect(notifier.state.isLoading, false);
    });

    test('addService sets error on failure', () async {
      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Add failed'));

      await notifier.addService({'title': 'Fail'});

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // deleteService
    // ---------------------------------------------------------------------------
    test('deleteService removes service', () async {
      // Pre-populate with one service
      when(() => mockApiClient.post<Service>(
            ApiConstants.profileMeServices,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => createService());

      await notifier.addService({'title': 'Svc', 'description': 'd'});
      expect(notifier.state.services.length, 1);

      // Stub DELETE
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeServices}/svc-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteService('svc-1');

      expect(notifier.state.services, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('deleteService sets error on failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeServices}/svc-1',
          )).thenThrow(Exception('Delete failed'));

      await notifier.deleteService('svc-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // addPackage
    // ---------------------------------------------------------------------------
    test('addPackage appends package', () async {
      final pkg = createPackage();

      when(() => mockApiClient.post<Package>(
            ApiConstants.profileMePackages,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => pkg);

      await notifier.addPackage({'name': 'New Package', 'price': 199});

      expect(notifier.state.packages.length, 1);
      expect(notifier.state.packages.first.id, 'pkg-1');
      expect(notifier.state.isLoading, false);
    });

    test('addPackage sets error on failure', () async {
      when(() => mockApiClient.post<Package>(
            ApiConstants.profileMePackages,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Add package failed'));

      await notifier.addPackage({'name': 'Fail'});

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // deletePackage
    // ---------------------------------------------------------------------------
    test('deletePackage removes package', () async {
      when(() => mockApiClient.post<Package>(
            ApiConstants.profileMePackages,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => createPackage());

      await notifier.addPackage({'name': 'Pkg', 'price': 99});
      expect(notifier.state.packages.length, 1);

      when(() => mockApiClient.delete(
            '${ApiConstants.profileMePackages}/pkg-1',
          )).thenAnswer((_) async => {});

      await notifier.deletePackage('pkg-1');

      expect(notifier.state.packages, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('deletePackage sets error on failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMePackages}/pkg-1',
          )).thenThrow(Exception('Delete failed'));

      await notifier.deletePackage('pkg-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // addTestimonial
    // ---------------------------------------------------------------------------
    test('addTestimonial appends testimonial', () async {
      final testimonial = createTestimonial();

      when(() => mockApiClient.post<Testimonial>(
            ApiConstants.profileMeTestimonials,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => testimonial);

      await notifier.addTestimonial({
        'client_name': 'Jane',
        'testimonial_text': 'Awesome!',
      });

      expect(notifier.state.testimonials.length, 1);
      expect(notifier.state.testimonials.first.id, 'test-1');
      expect(notifier.state.isLoading, false);
    });

    test('addTestimonial sets error on failure', () async {
      when(() => mockApiClient.post<Testimonial>(
            ApiConstants.profileMeTestimonials,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Add failed'));

      await notifier.addTestimonial({'client_name': 'X', 'testimonial_text': 'Y'});

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // deleteTestimonial
    // ---------------------------------------------------------------------------
    test('deleteTestimonial removes testimonial', () async {
      when(() => mockApiClient.post<Testimonial>(
            ApiConstants.profileMeTestimonials,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => createTestimonial());

      await notifier.addTestimonial({'client_name': 'J', 'testimonial_text': 'T'});
      expect(notifier.state.testimonials.length, 1);

      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeTestimonials}/test-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteTestimonial('test-1');

      expect(notifier.state.testimonials, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    // ---------------------------------------------------------------------------
    // setActiveTab
    // ---------------------------------------------------------------------------
    test('setActiveTab updates active tab', () {
      notifier.setActiveTab(2);
      expect(notifier.state.activeTab, 2);

      notifier.setActiveTab(0);
      expect(notifier.state.activeTab, 0);
    });
  });
}
