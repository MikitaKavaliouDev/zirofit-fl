import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_external_links_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_external_links_screen.dart';
import '../../helpers/test_setup.dart';

class FakeExternalLinksNotifier extends TrainerExternalLinksNotifier {
  TrainerExternalLinksState _s;
  FakeExternalLinksNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  TrainerExternalLinksState get state => _s;

  void emit(TrainerExternalLinksState ns) {
    _s = ns;
    super.state = ns;
  }

  @override
  Future<void> fetchLinks() async {}

  @override
  Future<void> addLink(Map<String, dynamic> data) async {
    final link = ExternalLink(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      profileId: 'p1',
      linkUrl: data['link_url'] as String? ?? '',
      label: data['label'] as String? ?? '',
      description: data['description'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(links: [...state.links, link]));
  }

  @override
  Future<void> updateLink(String id, Map<String, dynamic> data) async {
    final updated = state.links.map((l) {
      if (l.id == id) {
        return l.copyWith(
          label: data['label'] as String? ?? l.label,
          linkUrl: data['link_url'] as String? ?? l.linkUrl,
          description: data['description'] as String? ?? l.description,
        );
      }
      return l;
    }).toList();
    emit(state.copyWith(links: updated));
  }

  @override
  Future<void> deleteLink(String id) async {
    emit(state.copyWith(
      links: state.links.where((l) => l.id != id).toList(),
    ));
  }
}

Widget buildTestApp(TrainerExternalLinksState state) => ProviderScope(
      overrides: [
        trainerExternalLinksProvider
            .overrideWith((ref) => FakeExternalLinksNotifier(state)),
      ],
      child: const MaterialApp(
        home: TrainerExternalLinksScreen(),
      ),
    );

ExternalLink makeLink({
  String id = '1',
  String label = 'My Website',
  String linkUrl = 'https://example.com',
  String? description,
}) =>
    ExternalLink(
      id: id,
      profileId: 'p1',
      linkUrl: linkUrl,
      label: label,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerExternalLinksScreen', () {
    testWidgets('Test 1: Lists links with titles', (tester) async {
      final links = [
        makeLink(id: '1', label: 'My Website', linkUrl: 'https://example.com'),
        makeLink(
          id: '2',
          label: 'Instagram',
          linkUrl: 'https://instagram.com/trainer',
          description: 'Follow me',
        ),
      ];
      final state = TrainerExternalLinksState(
        links: links,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('My Website'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('External Links'), findsOneWidget);
    });

    testWidgets('Test 2: Add form validates URL', (tester) async {
      final state = TrainerExternalLinksState(links: [], isLoading: false);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state
      expect(find.text('No external links yet'), findsOneWidget);

      // Tap the Add button in the AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Link'), findsAtLeastNWidgets(1));

      // Try submitting without filling anything
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Should still show the dialog (validation prevents closing)
      expect(find.text('Add Link'), findsAtLeastNWidgets(1));

      // Fill title but invalid URL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title *'),
        'Test Link',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'URL *'),
        'not-a-valid-url',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Should still show the dialog (URL validation)
      expect(find.text('Add Link'), findsAtLeastNWidgets(1));

      // Now enter valid URL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'URL *'),
        'https://valid.com',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Dialog should close and link should be added
      // Note: in our fake notifier, addLink adds to state
      // (the fake notifier handles it synchronously)
    });

    testWidgets('Test 3: Delete confirms', (tester) async {
      final links = [
        makeLink(id: '1', label: 'My Website', linkUrl: 'https://example.com'),
        makeLink(id: '2', label: 'Blog', linkUrl: 'https://blog.com'),
      ];
      final state = TrainerExternalLinksState(
        links: links,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the popup menu buttons (one per card)
      final menuButtons = find.byType(PopupMenuButton<String>);
      expect(menuButtons, findsNWidgets(2));

      // Tap the popup menu on the first card
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap the "Delete" menu item
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Link'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "My Website"?'),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Note: In our fake notifier, deleteLink removes from state synchronously
      // So the dialog closes and the item is removed
    });

    testWidgets('Test 4: Empty state', (tester) async {
      final state = TrainerExternalLinksState(links: [], isLoading: false);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No external links yet'), findsOneWidget);
      expect(
        find.text('Add links to your website, blog, or social media'),
        findsOneWidget,
      );
      expect(find.text('Add Link'), findsAtLeastNWidgets(1));
    });
  });
}
