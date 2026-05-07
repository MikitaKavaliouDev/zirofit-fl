import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/public_trainer_profile_data.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';
import 'package:zirofit_fl/features/explore/screens/explore_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeExploreNotifier extends ExploreNotifier {
  final ExploreState _overriddenState;

  FakeExploreNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  ExploreState get state => _overriddenState;

  @override
  Future<void> fetchFeatured() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadFeatured() async {}

  @override
  Future<void> loadMetadata() async {}

  @override
  Future<void> loadUpcomingEvents({int limit = 10}) async {}

  @override
  Future<void> loadSpecialties() async {}

  @override
  Future<PublicTrainerProfileData?> fetchFullPublicProfile(
      String username) async {
    // Return profile data from the state's trainers so the destination
    // screen renders immediately instead of hitting a real API.
    final trainer = _overriddenState.trainers.isNotEmpty
        ? _overriddenState.trainers.first
        : Profile(
            id: 'trainer-1',
            userId: 'user-trainer-1',
            aboutMe: username,
            specialties: const ['Yoga'],
            businessCurrency: 'PLN',
            createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          );
    return PublicTrainerProfileData(profile: trainer);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Profile _createProfile({
  String id = 'trainer-1',
  String? aboutMe = 'John Doe',
  List<String> specialties = const ['Yoga', 'Pilates'],
  double? averageRating = 4.5,
  String? location = 'New York',
  String? profilePhotoPath,
  double? minServicePrice,
}) {
  return Profile(
    id: id,
    userId: 'user-$id',
    aboutMe: aboutMe,
    specialties: specialties,
    averageRating: averageRating,
    location: location,
    profilePhotoPath: profilePhotoPath,
    minServicePrice: minServicePrice,
    businessCurrency: 'PLN',
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

Widget buildTestApp(ExploreState state) {
  return ProviderScope(
    overrides: [
      exploreProvider.overrideWith((ref) => FakeExploreNotifier(state)),
    ],
    child: const MaterialApp(
      home: ExploreScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ExploreState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows trainer cards when data is loaded', (tester) async {
    final trainers = [
      _createProfile(
        id: 'trainer-1',
        aboutMe: 'John Doe',
        specialties: ['Yoga', 'Pilates'],
        averageRating: 4.5,
        location: 'New York',
      ),
      _createProfile(
        id: 'trainer-2',
        aboutMe: 'Jane Smith',
        specialties: ['HIIT'],
        averageRating: 4.8,
        location: 'Los Angeles',
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      ExploreState(trainers: trainers, isLoading: false),
    ));
    await tester.pump();

    // Check trainer names appear (each appears in featured + nearby sections)
    expect(find.text('John Doe'), findsAtLeast(1));
    expect(find.text('Jane Smith'), findsAtLeast(1));

    // Check first specialty shown (only first per card)
    expect(find.text('Yoga'), findsWidgets);
    expect(find.text('HIIT'), findsWidgets);

    // Check ratings appear
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);

    // Check locations appear
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Los Angeles'), findsOneWidget);
  });

  testWidgets('shows empty state when no trainers', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ExploreState(trainers: [], isLoading: false),
    ));
    await tester.pump();

    // Screen renders header with 'Select City' and empty RefreshIndicator
    expect(find.text('Select City'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const ExploreState(
        trainers: [],
        isLoading: false,
        error: 'Network error',
      ),
    ));
    await tester.pump();

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('navigates to trainer profile on card tap', (tester) async {
    final trainers = [
      _createProfile(
        id: 'trainer-1',
        aboutMe: 'John Doe',
        specialties: ['Yoga'],
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      ExploreState(trainers: trainers, isLoading: false),
    ));
    await tester.pump();

    // Tap on the first John Doe text (featured card)
    await tester.tap(find.text('John Doe').first);
    await tester.pumpAndSettle();

    // Should navigate to PublicTrainerProfileScreen
    expect(find.text('Specialties'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
  });

  testWidgets('pull to refresh is available', (tester) async {
    final trainers = [
      _createProfile(id: 'trainer-1', aboutMe: 'John Doe'),
    ];

    await tester.pumpWidget(buildTestApp(
      ExploreState(trainers: trainers, isLoading: false),
    ));
    await tester.pump();

    // Verify RefreshIndicator exists
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
