import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/features/blog/providers/blog_provider.dart';
import 'package:zirofit_fl/features/blog/screens/blog_post_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeBlogNotifier extends BlogNotifier {
  final BlogState _overriddenState;

  FakeBlogNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  BlogState get state => _overriddenState;

  @override
  Future<void> fetchPosts() async {}

  @override
  Future<void> fetchPost(String slug) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BlogPost _createPost({
  String id = 'post-1',
  String title = 'Test Post',
  String slug = 'test-post',
  String content = 'Full content of the blog post.',
  String? excerpt,
  String? coverImage,
}) {
  return BlogPost(
    id: id,
    title: title,
    slug: slug,
    content: content,
    excerpt: excerpt,
    coverImage: coverImage,
    published: true,
    authorId: 'author-1',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
    publishedAt: DateTime(2024, 1, 15),
  );
}

Widget buildTestApp(BlogState state, {String slug = 'test-post'}) {
  return ProviderScope(
    overrides: [
      blogProvider.overrideWith((ref) => FakeBlogNotifier(state)),
    ],
    child: MaterialApp(
      home: BlogPostScreen(slug: slug),
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
      const BlogState(isLoading: true),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows blog post content when loaded', (tester) async {
    final post = _createPost(
      title: 'My Blog Post',
      content: 'This is the content.',
    );

    await tester.pumpWidget(buildTestApp(
      BlogState(selectedPost: post, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('My Blog Post'), findsOneWidget);
    expect(find.text('This is the content.'), findsOneWidget);
    expect(find.text('15/1/2024'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BlogState(
          selectedPost: null, isLoading: false, error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Failed to load post'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('shows post not found when selectedPost is null and no error',
      (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BlogState(selectedPost: null, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('Post not found'), findsOneWidget);
  });
}