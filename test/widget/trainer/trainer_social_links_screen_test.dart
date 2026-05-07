import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_social_links_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_social_links_screen.dart';
import '../../helpers/test_setup.dart';

class FakeSocialLinks extends TrainerSocialLinksNotifier {
  TrainerSocialLinksState _s;
  FakeSocialLinks(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  TrainerSocialLinksState get state => _s;

  void emit(TrainerSocialLinksState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchLinks() async {}

  @override
  Future<void> addLink({
    required String platform,
    required String url,
  }) async {
    final link = SocialLink(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      profileId: 'p1',
      platform: platform,
      username: url.split('/').last,
      profileUrl: url,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(socialLinks: [...state.socialLinks, link]));
  }

  @override
  Future<void> updateLink({
    required String id,
    required String platform,
    required String url,
  }) async {
    final updated = state.socialLinks.map((l) {
      if (l.id == id) {
        return SocialLink(
          id: l.id,
          profileId: l.profileId,
          platform: platform,
          username: url.split('/').last,
          profileUrl: url,
          createdAt: l.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return l;
    }).toList();
    emit(state.copyWith(socialLinks: updated));
  }

  @override
  Future<void> deleteLink(String id) async {
    emit(state.copyWith(
      socialLinks: state.socialLinks.where((l) => l.id != id).toList(),
    ));
  }
}

Widget buildTestApp(TrainerSocialLinksState state) => ProviderScope(
      overrides: [
        trainerSocialLinksProvider
            .overrideWith((ref) => FakeSocialLinks(state)),
      ],
      child: const MaterialApp(
        home: TrainerSocialLinksScreen(),
      ),
    );

SocialLink makeLink({
  String id = '1',
  String platform = 'instagram',
  String profileUrl = 'https://instagram.com/testuser',
}) =>
    SocialLink(
      id: id,
      profileId: 'p1',
      platform: platform,
      username: profileUrl.split('/').last,
      profileUrl: profileUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerSocialLinksScreen', () {
    testWidgets('Test 1: Shows existing social links with icons',
        (tester) async {
      final links = [
        makeLink(
          id: '1',
          platform: 'instagram',
          profileUrl: 'https://instagram.com/trainer1',
        ),
        makeLink(
          id: '2',
          platform: 'youtube',
          profileUrl: 'https://youtube.com/trainer1',
        ),
      ];
      final state = TrainerSocialLinksState(
        socialLinks: links,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Platform names should be visible
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);

      // URLs should be visible
      expect(find.text('https://instagram.com/trainer1'), findsOneWidget);
      expect(find.text('https://youtube.com/trainer1'), findsOneWidget);

      // Screen title
      expect(find.text('Social Links'), findsOneWidget);
    });

    testWidgets('Test 2: Add form opens/stores/validates', (tester) async {
      final state = TrainerSocialLinksState(
        socialLinks: [],
        isLoading: false,
      );
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Empty state should be visible
      expect(find.text('No social links yet'), findsOneWidget);

      // Tap the Add button in the AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Social Link'), findsAtLeastNWidgets(1));

      // Fill in the URL field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile URL *'),
        'https://instagram.com/newtrainer',
      );

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // New link should appear
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('https://instagram.com/newtrainer'), findsOneWidget);
    });

    testWidgets('Test 3: Delete shows confirmation', (tester) async {
      final link = makeLink(
        id: '1',
        platform: 'instagram',
        profileUrl: 'https://instagram.com/todelete',
      );
      final state = TrainerSocialLinksState(
        socialLinks: [link],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Instagram'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion dialog
      expect(find.text('Delete Social Link'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete your Instagram link?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Instagram'), findsNothing);
    });

    testWidgets('Test 4: Empty state when no links', (tester) async {
      final state = TrainerSocialLinksState(
        socialLinks: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No social links yet'), findsOneWidget);
      expect(find.text('Add links to your social profiles'), findsOneWidget);
      expect(find.text('Add Social Link'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
