import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_social_links_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerSocialLinksNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerSocialLinksNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SocialLink createLink({
    String id = 'link-1',
    String platform = 'instagram',
    String username = 'testuser',
    String profileUrl = 'https://instagram.com/testuser',
  }) =>
      SocialLink(
        id: id,
        profileId: 'prof-1',
        platform: platform,
        username: username,
        profileUrl: profileUrl,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  /// Stubs the GET endpoint for `fetchLinks`.
  void stubFetchLinksSuccess({List<SocialLink>? links}) {
    final l = links ?? [createLink()];

    when(() => mockApiClient.get<List<SocialLink>>(
          ApiConstants.profileMeSocialLinks,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => l);
  }

  group('TrainerSocialLinksNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    test('Test 1: fetchLinks populates list', () async {
      final links = [
        createLink(
          id: '1',
          platform: 'instagram',
          profileUrl: 'https://instagram.com/user1',
        ),
        createLink(
          id: '2',
          platform: 'youtube',
          profileUrl: 'https://youtube.com/user2',
        ),
      ];
      stubFetchLinksSuccess(links: links);

      expect(notifier.state.socialLinks, isEmpty);
      expect(notifier.state.isLoading, false);

      await notifier.fetchLinks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.socialLinks.length, 2);
      expect(notifier.state.socialLinks[0].platform, 'instagram');
      expect(notifier.state.socialLinks[1].platform, 'youtube');
    });

    test('fetchLinks sets error on failure', () async {
      when(() => mockApiClient.get<List<SocialLink>>(
            ApiConstants.profileMeSocialLinks,
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Server error'));

      await notifier.fetchLinks();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.socialLinks, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // addLink
    // ---------------------------------------------------------------------------

    test('Test 2: addLink creates and adds to list', () async {
      final newLink = createLink(
        id: 'new-1',
        platform: 'twitter',
        profileUrl: 'https://twitter.com/newuser',
      );

      when(() => mockApiClient.post<SocialLink>(
            ApiConstants.profileMeSocialLinks,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => newLink);

      await notifier.addLink(
        platform: 'twitter',
        url: 'https://twitter.com/newuser',
      );

      expect(notifier.state.socialLinks.length, 1);
      expect(notifier.state.socialLinks.first.id, 'new-1');
      expect(notifier.state.socialLinks.first.platform, 'twitter');
      expect(notifier.state.isLoading, false);

      verify(() => mockApiClient.post<SocialLink>(
            ApiConstants.profileMeSocialLinks,
            body: {
              'platform': 'twitter',
              'profile_url': 'https://twitter.com/newuser',
            },
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });

    test('addLink sets error on failure', () async {
      when(() => mockApiClient.post<SocialLink>(
            ApiConstants.profileMeSocialLinks,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Add failed'));

      await notifier.addLink(platform: 'instagram', url: 'https://instagram.com/fail');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // updateLink
    // ---------------------------------------------------------------------------

    test('Test 3: updateLink modifies link', () async {
      // Pre-populate with a link
      when(() => mockApiClient.post<SocialLink>(
            ApiConstants.profileMeSocialLinks,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => createLink(id: 'link-1', platform: 'instagram'));

      await notifier.addLink(platform: 'instagram', url: 'https://instagram.com/old');
      expect(notifier.state.socialLinks.length, 1);

      // Stub update
      final updatedLink = createLink(
        id: 'link-1',
        platform: 'youtube',
        profileUrl: 'https://youtube.com/new',
      );

      when(() => mockApiClient.put<SocialLink>(
            '${ApiConstants.profileMeSocialLinks}/link-1',
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => updatedLink);

      await notifier.updateLink(
        id: 'link-1',
        platform: 'youtube',
        url: 'https://youtube.com/new',
      );

      expect(notifier.state.socialLinks.length, 1);
      expect(notifier.state.socialLinks.first.platform, 'youtube');
      expect(notifier.state.socialLinks.first.profileUrl, 'https://youtube.com/new');
      expect(notifier.state.isLoading, false);
    });

    test('updateLink sets error on failure', () async {
      when(() => mockApiClient.put<SocialLink>(
            '${ApiConstants.profileMeSocialLinks}/link-1',
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Update failed'));

      await notifier.updateLink(
        id: 'link-1',
        platform: 'instagram',
        url: 'https://instagram.com/fail',
      );

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // deleteLink
    // ---------------------------------------------------------------------------

    test('Test 4: deleteLink removes from list', () async {
      // Pre-populate with a link
      when(() => mockApiClient.post<SocialLink>(
            ApiConstants.profileMeSocialLinks,
            body: any(named: 'body'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => createLink(id: 'link-1'));

      await notifier.addLink(platform: 'instagram', url: 'https://instagram.com/user');
      expect(notifier.state.socialLinks.length, 1);

      // Stub DELETE
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeSocialLinks}/link-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteLink('link-1');

      expect(notifier.state.socialLinks, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('deleteLink sets error on failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.profileMeSocialLinks}/link-1',
          )).thenThrow(Exception('Delete failed'));

      await notifier.deleteLink('link-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // reorderLinks
    // ---------------------------------------------------------------------------

    test('reorderLinks updates list order', () {
      final link1 = createLink(id: '1', platform: 'instagram');
      final link2 = createLink(id: '2', platform: 'twitter');

      // Manually set state with two links
      notifier = TrainerSocialLinksNotifier(apiClient: mockApiClient);
      // We need to inject via a method; use a workaround by calling addLink via API
      // Since we can't set state directly, we test via the reorder method
      // after populating through actual API stubs
      notifier.reorderLinks([link1, link2]);

      expect(notifier.state.socialLinks.length, 2);
      expect(notifier.state.socialLinks[0].id, '1');
      expect(notifier.state.socialLinks[1].id, '2');

      notifier.reorderLinks([link2, link1]);

      expect(notifier.state.socialLinks[0].id, '2');
      expect(notifier.state.socialLinks[1].id, '1');
    });
  });
}
