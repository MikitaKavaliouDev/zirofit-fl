import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/transformation_photo.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Profile _createDummyProfile({
  String id = 'trainer-1',
  String userId = 'user-1',
  String? aboutMe = 'Test Trainer',
  String? location = 'New York',
  double? averageRating = 4.5,
  List<String> specialties = const ['Strength', 'Cardio'],
  String? certifications = 'NASM',
  String? philosophy = 'Train hard',
  String? methodology = 'Progressive overload',
  double? minServicePrice = 50.0,
  String businessCurrency = 'USD',
  String? profilePhotoPath,
}) {
  return Profile(
    id: id,
    userId: userId,
    aboutMe: aboutMe,
    location: location,
    averageRating: averageRating,
    specialties: specialties,
    certifications: certifications,
    philosophy: philosophy,
    methodology: methodology,
    minServicePrice: minServicePrice,
    businessCurrency: businessCurrency,
    profilePhotoPath: profilePhotoPath,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

List<Package> _dummyPackages() => [
      Package(
        id: 'pkg-1',
        name: 'Starter Pack',
        description: 'Get started with 5 sessions',
        price: 199.99,
        numberOfSessions: 5,
        isActive: true,
        stripeProductId: 'prod_1',
        stripePriceId: 'price_1',
        trainerId: 'trainer-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Package(
        id: 'pkg-2',
        name: 'Premium Pack',
        description: '12 sessions with full support',
        price: 449.99,
        numberOfSessions: 12,
        isActive: true,
        stripeProductId: 'prod_2',
        stripePriceId: 'price_2',
        trainerId: 'trainer-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

List<Service> _dummyServices() => [
      Service(
        id: 'svc-1',
        profileId: 'profile-1',
        title: 'Personal Training',
        description: 'One-on-one personal training sessions',
        price: 75.0,
        currency: 'USD',
        duration: 60,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Service(
        id: 'svc-2',
        profileId: 'profile-1',
        title: 'Nutrition Coaching',
        description: 'Customized nutrition plans',
        price: 50.0,
        currency: 'USD',
        duration: 45,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

List<TransformationPhoto> _dummyTransformations() => [
      TransformationPhoto(
        id: 'trans-1',
        profileId: 'profile-1',
        imagePath: 'https://example.com/photo1.jpg',
        caption: '12 week transformation',
        clientName: 'Jane D.',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      TransformationPhoto(
        id: 'trans-2',
        profileId: 'profile-1',
        imagePath: 'https://example.com/photo2.jpg',
        caption: '8 week progress',
        clientName: 'John S.',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

List<Testimonial> _dummyTestimonials() => [
      Testimonial(
        id: 'test-1',
        profileId: 'profile-1',
        clientName: 'Alice W.',
        testimonialText: 'Amazing trainer! Helped me reach my goals.',
        rating: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      Testimonial(
        id: 'test-2',
        profileId: 'profile-1',
        clientName: 'Bob M.',
        testimonialText: 'Very knowledgeable and supportive.',
        rating: 4,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

List<SocialLink> _dummySocialLinks() => [
      SocialLink(
        id: 'social-1',
        profileId: 'profile-1',
        platform: 'Instagram',
        username: 'trainer_jane',
        profileUrl: 'https://instagram.com/trainer_jane',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      SocialLink(
        id: 'social-2',
        profileId: 'profile-1',
        platform: 'YouTube',
        username: 'trainer_jane_fitness',
        profileUrl: 'https://youtube.com/@trainer_jane_fitness',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
    ];

/// Wraps a widget in a ProviderScope with mocked explore provider.
Future<void> pumpWithMocks(
  WidgetTester tester, {
  required Widget child,
  required MockApiClient mockApiClient,
  List<Override> additionalOverrides = const [],
}) async {
  final notifier = ExploreNotifier(apiClient: mockApiClient);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exploreProvider.overrideWith((ref) => notifier),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

/// Stubs the public profile GET endpoint with the correct generic type
/// (<Map<String, dynamic>>) matching the production code.
void mockPublicProfileGet(
  MockApiClient mockApiClient, {
  required String path,
  required Map<String, dynamic> responseData,
}) {
  when(() => mockApiClient.get<Map<String, dynamic>>(
        path,
        queryParams: any(named: 'queryParams'),
      )).thenAnswer((_) async => responseData);
}

/// Stubs the connect POST endpoint (the call site uses no explicit type,
/// so dynamic matches).
void mockConnectPost(
  MockApiClient mockApiClient, {
  required String path,
  Map<String, dynamic>? responseData,
}) {
  when(() => mockApiClient.post<dynamic>(
        path,
        body: any(named: 'body'),
      )).thenAnswer((_) async => responseData ?? {});
}

Map<String, dynamic> _fullProfileJson({
  required Profile profile,
  List<Package> packages = const [],
  List<Service> services = const [],
  List<TransformationPhoto> transformations = const [],
  List<Testimonial> testimonials = const [],
  List<SocialLink> socialLinks = const [],
}) {
  return {
    'data': {
      'profile': profile.toJson(),
      'packages': packages.map((p) => p.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'transformations':
          transformations.map((t) => t.toJson()).toList(),
      'testimonials':
          testimonials.map((t) => t.toJson()).toList(),
      'social_links': socialLinks.map((l) => l.toJson()).toList(),
    },
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('PublicTrainerProfileScreen', () {
    late MockApiClient mockApiClient;
    late Profile profile;

    setUp(() {
      mockApiClient = MockApiClient();
      profile = _createDummyProfile();
    });

    // =====================================================================
    // Test 1: Shows all profile sections
    // =====================================================================
    testWidgets('Test 1: Shows all profile sections',
        (tester) async {
      final packages = _dummyPackages();
      final services = _dummyServices();
      final transformations = _dummyTransformations();
      final testimonials = _dummyTestimonials();
      final socialLinks = _dummySocialLinks();

      mockPublicProfileGet(
        mockApiClient,
        path: ApiConstants.trainerPublicProfile('Test Trainer'),
        responseData: _fullProfileJson(
          profile: profile,
          packages: packages,
          services: services,
          transformations: transformations,
          testimonials: testimonials,
          socialLinks: socialLinks,
        ),
      );

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      await tester.pumpAndSettle();

      // Header: name, location, rating
      expect(find.text('Test Trainer'), findsWidgets);
      expect(find.text('New York'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);

      // Philosophy
      expect(find.text('Train hard'), findsOneWidget);

      // Methodology
      expect(find.text('Progressive overload'), findsOneWidget);

      // Specialties
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);

      // Certifications
      expect(find.text('NASM'), findsOneWidget);

      // Price info
      expect(find.text('From 50.00 USD'), findsOneWidget);

      // Services section
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Personal Training'), findsOneWidget);
      expect(find.text('75.00 USD'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('Nutrition Coaching'), findsOneWidget);

      // Packages section
      expect(find.text('Packages'), findsOneWidget);
      expect(find.text('Starter Pack'), findsOneWidget);
      expect(find.text('199.99 USD'), findsOneWidget);
      expect(find.text('5 sessions'), findsOneWidget);
      expect(find.text('Premium Pack'), findsOneWidget);
      expect(find.text('449.99 USD'), findsOneWidget);
      expect(find.text('12 sessions'), findsOneWidget);

      // Transformation photos
      expect(find.text('Transformation Photos'), findsOneWidget);
      expect(find.text('Jane D.'), findsOneWidget);
      expect(find.text('John S.'), findsOneWidget);

      // Testimonials
      expect(find.text('Testimonials'), findsOneWidget);
      expect(find.text('Amazing trainer! Helped me reach my goals.'),
          findsOneWidget);
      expect(find.text('Alice W.'), findsOneWidget);

      // Social links
      expect(find.text('Social Links'), findsOneWidget);
      expect(find.textContaining('Instagram'), findsWidgets);
      expect(find.textContaining('YouTube'), findsWidgets);
    });

    // =====================================================================
    // Test 2: Packages shown
    // =====================================================================
    testWidgets('Test 2: Packages shown with purchase CTA',
        (tester) async {
      final packages = _dummyPackages();

      mockPublicProfileGet(
        mockApiClient,
        path: ApiConstants.trainerPublicProfile('Test Trainer'),
        responseData: _fullProfileJson(
          profile: profile,
          packages: packages,
        ),
      );

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      await tester.pumpAndSettle();

      // Verify packages section title
      expect(find.text('Packages'), findsOneWidget);

      // Verify package names and prices
      expect(find.text('Starter Pack'), findsOneWidget);
      expect(find.text('199.99 USD'), findsOneWidget);
      expect(find.text('Premium Pack'), findsOneWidget);
      expect(find.text('449.99 USD'), findsOneWidget);

      // Verify session counts
      expect(find.text('5 sessions'), findsOneWidget);
      expect(find.text('12 sessions'), findsOneWidget);

      // Verify Purchase buttons exist
      expect(find.text('Purchase'), findsNWidgets(2));
    });

    // =====================================================================
    // Test 3: Connect button works
    // =====================================================================
    testWidgets('Test 3: Connect button works', (tester) async {
      // Mock successful public profile fetch
      mockPublicProfileGet(
        mockApiClient,
        path: ApiConstants.trainerPublicProfile('Test Trainer'),
        responseData: _fullProfileJson(profile: profile),
      );

      // Mock successful connect request
      // requestConnectTrainer calls _api.post(...) which infers <dynamic>
      when(() => mockApiClient.post<dynamic>(
            ApiConstants.clientConnectTrainer('user-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      await tester.pumpAndSettle();

      // Scroll down to where the button is (below the fold)
      await tester.dragUntilVisible(
        find.widgetWithText(OutlinedButton, 'Connect with Trainer'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();

      // Verify Connect button exists and is tappable
      final connectButton =
          find.widgetWithText(OutlinedButton, 'Connect with Trainer');
      expect(connectButton, findsOneWidget);

      final button = tester.widget<OutlinedButton>(connectButton);
      expect(button.onPressed, isNotNull);

      // Tap the Connect button
      await tester.tap(connectButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify the mock was called
      verify(() => mockApiClient.post<dynamic>(
            ApiConstants.clientConnectTrainer('user-1'),
            body: any(named: 'body'),
          )).called(1);
    });

    // =====================================================================
    // Test 4: Book Session navigates
    // =====================================================================
    testWidgets('Test 4: Book Session navigates', (tester) async {
      mockPublicProfileGet(
        mockApiClient,
        path: ApiConstants.trainerPublicProfile('Test Trainer'),
        responseData: _fullProfileJson(profile: profile),
      );

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      await tester.pumpAndSettle();

      // Scroll down to the action buttons
      await tester.dragUntilVisible(
        find.widgetWithText(FilledButton, 'Book Session'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      // Verify Book Session button exists
      final bookButton =
          find.widgetWithText(FilledButton, 'Book Session');
      expect(bookButton, findsOneWidget);

      // Verify button is actionable
      final button = tester.widget<FilledButton>(bookButton);
      expect(button.onPressed, isNotNull);
    });

    // =====================================================================
    // Test 5: Loading state
    // =====================================================================
    testWidgets('Test 5: Loading state shown while fetching',
        (tester) async {
      // Use a completer to delay the API response so we can observe loading
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) => completer.future);

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      // Only pump once — the future hasn't resolved yet
      await tester.pump();

      // Loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future so no dangling async tasks remain
      completer.complete({'data': {'profile': profile.toJson()}});
      await tester.pumpAndSettle();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // =====================================================================
    // Test 6: Error state
    // =====================================================================
    testWidgets('Test 6: Error state shown on fetch failure',
        (tester) async {
      // Make the GET throw an exception
      when(() => mockApiClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerPublicProfile('Test Trainer')),
          type: DioExceptionType.badResponse,
          error: 'Not found',
        ),
      );

      await pumpWithMocks(
        tester,
        child: PublicTrainerProfileScreen(trainer: profile),
        mockApiClient: mockApiClient,
      );
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.textContaining('Unable to load full profile'),
          findsOneWidget);

      // Verify the detailed error message
      expect(
        find.textContaining('Could not load full profile'),
        findsOneWidget,
      );

      // Verify retry button
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
