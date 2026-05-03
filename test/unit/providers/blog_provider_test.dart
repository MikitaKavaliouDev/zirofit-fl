import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/blog/providers/blog_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_setup.dart';

void main() {
  late MockApiClient mockApiClient;
  late BlogNotifier notifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = BlogNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  Map<String, dynamic> blogPostJson({
    String id = 'post-1',
    String title = 'Test Post',
    String slug = 'test-post',
    String content = 'Full content',
    String? excerpt,
    String? coverImage,
    bool published = true,
  }) {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'cover_image': coverImage,
      'published': published,
      'author_id': 'author-1',
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'published_at': 1700000000000,
    };
  }

  Map<String, dynamic> responseWithData(List<Map<String, dynamic>> items) {
    return <String, dynamic>{'data': items};
  }

  Map<String, dynamic> responseWithSingleData(Map<String, dynamic> item) {
    return <String, dynamic>{'data': item};
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('posts empty, selectedPost null, isLoading=false', () {
      final state = notifier.state;
      expect(state.posts, isEmpty);
      expect(state.selectedPost, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchPosts
  // ---------------------------------------------------------------------------

  group('fetchPosts', () {
    test('populates posts on success', () async {
      final post1 = blogPostJson(
        id: 'post-1',
        title: 'First Post',
        slug: 'first-post',
        excerpt: 'Excerpt 1',
      );
      final post2 = blogPostJson(
        id: 'post-2',
        title: 'Second Post',
        slug: 'second-post',
        excerpt: 'Excerpt 2',
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([post1, post2]));

      final future = notifier.fetchPosts();
      // Intermediate loading state
      expect(notifier.state.isLoading, true);

      await future;

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.posts.length, 2);
      expect(state.posts[0].id, 'post-1');
      expect(state.posts[0].title, 'First Post');
      expect(state.posts[1].id, 'post-2');
      expect(state.posts[1].title, 'Second Post');
      expect(state.error, isNull);
    });

    test('handles empty list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([]));

      await notifier.fetchPosts();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.posts, isEmpty);
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blog,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.blog),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.blog),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Server error'},
        ),
      ));

      await notifier.fetchPosts();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.posts, isEmpty);
      expect(state.error, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchPost
  // ---------------------------------------------------------------------------

  group('fetchPost', () {
    test('populates selectedPost on success', () async {
      final postJson = blogPostJson(
        id: 'post-1',
        title: 'Single Post',
        slug: 'single-post',
        content: 'Full article content here',
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blogPost('single-post'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithSingleData(postJson));

      final future = notifier.fetchPost('single-post');
      // Intermediate loading state
      expect(notifier.state.isLoading, true);

      await future;

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.selectedPost, isNotNull);
      expect(state.selectedPost!.id, 'post-1');
      expect(state.selectedPost!.title, 'Single Post');
      expect(state.selectedPost!.content, 'Full article content here');
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.blogPost('unknown-slug'),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.blogPost('unknown-slug')),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.blogPost('unknown-slug')),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Post not found'},
        ),
      ));

      await notifier.fetchPost('unknown-slug');

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.selectedPost, isNull);
      expect(state.error, isNotNull);
    });
  });
}
