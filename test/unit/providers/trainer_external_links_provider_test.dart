import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_external_links_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerExternalLinksNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerExternalLinksNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ExternalLink createLink({
    String id = 'link-1',
    String label = 'My Website',
    String linkUrl = 'https://example.com',
    String? description,
  }) =>
      ExternalLink(
        id: id,
        profileId: 'prof-1',
        linkUrl: linkUrl,
        label: label,
        description: description,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  List<ExternalLink> createLinks() => [
        createLink(
          id: 'link-1',
          label: 'My Website',
          linkUrl: 'https://example.com',
        ),
        createLink(
          id: 'link-2',
          label: 'Instagram',
          linkUrl: 'https://instagram.com/trainer',
          description: 'Follow me on Instagram',
        ),
      ];

  group('TrainerExternalLinksNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('Test 1: fetchLinks populates list', () async {
      final links = createLinks();

      when(() => mockApiClient.get<List<ExternalLink>>(
            ApiConstants.profileMeExternalLinks,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => links);

      await notifier.fetchLinks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.links.length, 2);
      expect(notifier.state.links[0].label, 'My Website');
      expect(notifier.state.links[1].label, 'Instagram');
    });

    // ---------------------------------------------------------------------------
    // Add link
    // ---------------------------------------------------------------------------
    test('Test 2: addLink creates link', () async {
      final newLink = createLink(
        id: 'link-3',
        label: 'New Site',
        linkUrl: 'https://newsite.com',
      );

      final data = {
        'label': 'New Site',
        'link_url': 'https://newsite.com',
      };

      when(() => mockApiClient.post<ExternalLink>(
            ApiConstants.profileMeExternalLinks,
            body: data,
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => newLink);

      await notifier.addLink(data);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.links.length, 1);
      expect(notifier.state.links[0].label, 'New Site');
    });

    // ---------------------------------------------------------------------------
    // Update link
    // ---------------------------------------------------------------------------
    test('Test 3: updateLink modifies link', () async {
      // Start with one link in state
      notifier = TrainerExternalLinksNotifier(apiClient: mockApiClient);
      // Manually set state to have one link
      final initialLink = createLink();
      // We need to set state - let's add it first
      when(() => mockApiClient.post<ExternalLink>(
            ApiConstants.profileMeExternalLinks,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => initialLink);

      await notifier.addLink({'label': 'Old Name', 'link_url': 'https://old.com'});

      // Now update it
      final updatedLink = createLink(
        label: 'Updated Name',
        linkUrl: 'https://updated.com',
      );

      final updateData = {
        'label': 'Updated Name',
        'link_url': 'https://updated.com',
      };

      when(() => mockApiClient.put<ExternalLink>(
            '${ApiConstants.profileMeExternalLinks}/link-1',
            body: updateData,
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => updatedLink);

      await notifier.updateLink('link-1', updateData);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.links.length, 1);
      expect(notifier.state.links[0].label, 'Updated Name');
      expect(notifier.state.links[0].linkUrl, 'https://updated.com');
    });

    // ---------------------------------------------------------------------------
    // Delete link
    // ---------------------------------------------------------------------------
    test('Test 4: deleteLink removes link', () async {
      // Start with two links
      final links = createLinks();

      when(() => mockApiClient.get<List<ExternalLink>>(
            ApiConstants.profileMeExternalLinks,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => links);

      await notifier.fetchLinks();
      expect(notifier.state.links.length, 2);

      // Delete one
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeExternalLinks}/link-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteLink('link-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.links.length, 1);
      expect(notifier.state.links[0].id, 'link-2');
    });

    // ---------------------------------------------------------------------------
    // Error states
    // ---------------------------------------------------------------------------
    test('Test 5: error states are handled', () async {
      when(() => mockApiClient.get<List<ExternalLink>>(
            ApiConstants.profileMeExternalLinks,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Network failure'));

      await notifier.fetchLinks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.links, isEmpty);
    });
  });
}
