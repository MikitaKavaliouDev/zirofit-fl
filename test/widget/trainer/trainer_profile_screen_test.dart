import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_branding_provider.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_profile_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake TrainerProfileNotifier
// ---------------------------------------------------------------------------
class FakeTP extends TrainerProfileNotifier {
  TrainerProfileState _s;
  FakeTP(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  TrainerProfileState get state => _s;
  void emit(TrainerProfileState ns) {
    _s = ns;
    super.state = ns;
  }
  @override
  Future<void> fetchProfile() async {}
  @override
  Future<void> updateTextContent(String field, String content) async {}
  @override
  Future<void> addService(Map<String, dynamic> data) async {}
  @override
  Future<void> updateService(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteService(String id) async {}
  @override
  Future<void> addPackage(Map<String, dynamic> data) async {}
  @override
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deletePackage(String id) async {}
  @override
  Future<void> addTestimonial(Map<String, dynamic> data) async {}
  @override
  Future<void> deleteTestimonial(String id) async {}
  @override
  Future<void> addBenefit(Map<String, dynamic> data) async {}
  @override
  Future<void> deleteBenefit(String id) async {}
  @override
  void setActiveTab(int tab) {}
}

// ---------------------------------------------------------------------------
// Fake TrainerBrandingNotifier
// ---------------------------------------------------------------------------

class FakeTB extends TrainerBrandingNotifier {
  TrainerBrandingState _s;
  FakeTB(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  TrainerBrandingState get state => _s;
  void emit(TrainerBrandingState ns) {
    _s = ns;
    super.state = ns;
  }
  @override
  Future<void> fetchBranding() async {}
  @override
  Future<void> uploadAvatar(String imagePath) async {}
  @override
  Future<void> uploadBanner(String imagePath) async {}
}

// ---------------------------------------------------------------------------
// Build helper
// ---------------------------------------------------------------------------

Widget buildScreen({
  required TrainerProfileState profileState,
  TrainerBrandingState? brandingState,
}) {
  final branding = brandingState ?? const TrainerBrandingState();
  return ProviderScope(
    overrides: [
      trainerProfileProvider.overrideWith((ref) => FakeTP(profileState)),
      trainerBrandingProvider.overrideWith((ref) => FakeTB(branding)),
    ],
    child: const MaterialApp(home: TrainerProfileScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  testWidgets('shows loading indicator when loading without profile',
      (t) async {
    await t.pumpWidget(buildScreen(
      profileState: const TrainerProfileState(isLoading: true),
    ));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows core info tabs when data loaded', (t) async {
    final p = Profile(
      id: '1',
      userId: '1',
      completionPercentage: 75,
      createdAt: now,
      updatedAt: now,
    );
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(profile: p, isLoading: false),
    ));
    await t.pumpAndSettle();
    expect(find.text('Trainer Profile'), findsOneWidget);
    expect(find.text('Core Info'), findsOneWidget);
    expect(find.text('75% complete'), findsOneWidget);
  });

  testWidgets('shows error state', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: const TrainerProfileState(isLoading: false, error: 'err'),
    ));
    await t.pumpAndSettle();
    expect(find.text('Trainer Profile'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Banner & Avatar tests
  // ---------------------------------------------------------------------------

  testWidgets('shows default banner placeholder when no banner', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Add Banner Image'), findsOneWidget);
  });

  testWidgets('shows current banner image from branding state', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
      brandingState: const TrainerBrandingState(
        bannerUrl: 'https://example.com/banner.jpg',
      ),
    ));
    await t.pump();
    // An Image.network widget should be present for the banner
    expect(find.byType(Image), findsOneWidget);
    // The camera edit overlay buttons exist (both banner and avatar)
    expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(2));
  });

  testWidgets('shows avatar placeholder when no avatar', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
    ));
    await t.pumpAndSettle();
    // Person icon as avatar placeholder
    expect(find.byIcon(Icons.person), findsWidgets);
  });

  testWidgets('shows upload progress indicator when uploading', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
      brandingState: const TrainerBrandingState(
        isUploading: true,
        uploadProgress: 0.5,
      ),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('Uploading...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('shows upload error message', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
      brandingState: const TrainerBrandingState(
        error: 'Upload failed. Please try again.',
      ),
    ));
    await t.pumpAndSettle();
    expect(
      find.text('Upload failed. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('banner edit button triggers bottom sheet', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
    ));
    await t.pumpAndSettle();

    // Tap banner edit button (first camera icon in the header area)
    final editButtons = find.byIcon(Icons.camera_alt);
    expect(editButtons, findsAtLeastNWidgets(2));

    // Tap the banner edit button (first one in banner area, top-right)
    await t.tap(editButtons.first);
    await t.pumpAndSettle();

    // Bottom sheet should show
    expect(find.text('Change Banner Image'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('avatar edit button triggers bottom sheet', (t) async {
    await t.pumpWidget(buildScreen(
      profileState: TrainerProfileState(
        profile: Profile(
          id: '1',
          userId: '1',
          completionPercentage: 0,
          createdAt: now,
          updatedAt: now,
        ),
        isLoading: false,
      ),
    ));
    await t.pumpAndSettle();

    // Find avatar edit button (second camera icon, bottom-right on avatar)
    final editButtons = find.byIcon(Icons.camera_alt);
    expect(editButtons, findsAtLeastNWidgets(2));

    // Tap the avatar edit button (last one)
    await t.tap(editButtons.last);
    await t.pumpAndSettle();

    // Bottom sheet should show
    expect(find.text('Change Profile Photo'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });
}
