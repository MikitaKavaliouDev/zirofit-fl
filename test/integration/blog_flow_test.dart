import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/blog/providers/blog_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures — snake_case keys matching backend wire format
// ---------------------------------------------------------------------------

const _ts = 1704067200000;

Map<String, dynamic> _blogPostJson({
  String id = 'post-1',
  String title = 'Test Post',
  String slug = 'test-post',
  String content = 'Full content',
  String? excerpt,
  String? coverImage,
  bool published = true,
}) => {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'cover_image': coverImage,
      'published': published,
      'author_id': 'author-1',
      'created_at': _ts,
      'updated_at': _ts,
      'published_at': _ts,
    };

Map<String, dynamic> _responseWithData(List<Map<String, dynamic>> items) =>
    <String, dynamic>{'data': items};

Map<String, dynamic> _responseWithSingleData(Map<String, dynamic> item) =>
    <String, dynamic>{'data': item};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      blogProvider.overrideWith(
        (ref) => BlogNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() => container.dispose());

  group('BlogNotifier', () {
    test('initial state has empty posts and is not loading', () {
      final state = container.read(blogProvider);
      expect(state.posts, isEmpty);
      expect(state.selectedPost, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchPosts populates the post list', () async {
      final post1 = _blogPostJson(
        id: 'post-1',
        title: 'First Post',
        slug: 'first-post',
      );
      final post2 = _blogPostJson(
        id: 'post-2',
        title: 'Second Post',
        slug: 'second-post',
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData([post1, post2]));

      await container.read(blogProvider.notifier).fetchPosts();

      final state = container.read(blogProvider);
      expect(state.posts, hasLength(2));
      expect(state.posts[0].id, 'post-1');
      expect(state.posts[0].title, 'First Post');
      expect(state.posts[1].slug, 'second-post');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchPosts handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithData([]));

      await container.read(blogProvider.notifier).fetchPosts();

      final state = container.read(blogProvider);
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchPosts sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('API error'));

      await container.read(blogProvider.notifier).fetchPosts();

      final state = container.read(blogProvider);
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('fetchPost populates selectedPost on success', () async {
      final postJson = _blogPostJson(
        id: 'post-1',
        title: 'Single Post',
        slug: 'single-post',
        content: 'Full article content here',
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blogPost('single-post'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => _responseWithSingleData(postJson));

      await container.read(blogProvider.notifier).fetchPost('single-post');

      final state = container.read(blogProvider);
      expect(state.isLoading, isFalse);
      expect(state.selectedPost, isNotNull);
      expect(state.selectedPost!.id, 'post-1');
      expect(state.selectedPost!.title, 'Single Post');
      expect(state.selectedPost!.content, 'Full article content here');
      expect(state.error, isNull);
    });

    test('fetchPost sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blogPost('unknown'),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Not found'));

      await container.read(blogProvider.notifier).fetchPost('unknown');

      final state = container.read(blogProvider);
      expect(state.isLoading, isFalse);
      expect(state.selectedPost, isNull);
      expect(state.error, isNotNull);
    });

    test('clearError resets the error state', () async {
      // Force an error
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Some error'));

      await container.read(blogProvider.notifier).fetchPosts();
      expect(container.read(blogProvider).error, isNotNull);

      // Act
      container.read(blogProvider.notifier).clearError();

      // Assert
      expect(container.read(blogProvider).error, isNull);
    });
  });
}
