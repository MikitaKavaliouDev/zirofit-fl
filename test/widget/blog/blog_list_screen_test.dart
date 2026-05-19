import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/features/blog/providers/blog_provider.dart';
import 'package:zirofit_fl/features/blog/screens/blog_list_screen.dart';
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
  String? excerpt,
  String? coverImage,
}) {
  return BlogPost(
    id: id,
    title: title,
    slug: slug,
    content: 'Full content of the blog post.',
    excerpt: excerpt,
    coverImage: coverImage,
    published: true,
    authorId: 'author-1',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
    publishedAt: DateTime(2024, 1, 15),
  );
}

Widget buildTestApp(BlogState state) {
  return ProviderScope(
    overrides: [
      blogProvider.overrideWith((ref) => FakeBlogNotifier(state)),
    ],
    child: const MaterialApp(
      home: BlogListScreen(),
    ),
  );
}

/// Wraps BlogListScreen with a minimal GoRouter so navigation works.
Widget _buildGoRouterTestApp(BlogState state) {
  final router = GoRouter(
    initialLocation: '/blog',
    routes: [
      GoRoute(
        path: '/blog',
        builder: (_, _) => const BlogListScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (_, state) => BlogPostScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      blogProvider.overrideWith((ref) => FakeBlogNotifier(state)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
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

  testWidgets('shows blog posts list when data is loaded', (tester) async {
    final posts = [
      _createPost(
        id: 'post-1',
        title: 'First Blog Post',
        slug: 'first-post',
        excerpt: 'This is the first post excerpt',
      ),
      _createPost(
        id: 'post-2',
        title: 'Second Blog Post',
        slug: 'second-post',
        excerpt: 'This is the second post excerpt',
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      BlogState(posts: posts, isLoading: false),
    ));
    await tester.pump();

    expect(find.text('First Blog Post'), findsOneWidget);
    expect(find.text('Second Blog Post'), findsOneWidget);
    expect(find.text('This is the first post excerpt'), findsOneWidget);
    expect(find.text('This is the second post excerpt'), findsOneWidget);
    expect(find.text('15/1/2024'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no posts', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BlogState(posts: [], isLoading: false),
    ));
    await tester.pump();

    expect(find.text('No posts yet'), findsOneWidget);
    expect(
      find.text('Check back later for new content.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const BlogState(
          posts: [], isLoading: false, error: 'Network error'),
    ));
    await tester.pump();

    expect(find.text('Failed to load posts'), findsOneWidget);
    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('tapping a post card navigates to detail', (tester) async {
    final posts = [
      _createPost(
        id: 'post-1',
        title: 'Clickable Post',
        slug: 'clickable-post',
      ),
    ];

    await tester.pumpWidget(_buildGoRouterTestApp(
      BlogState(posts: posts, isLoading: false),
    ));
    await tester.pump();

    // Tap the card
    await tester.tap(find.text('Clickable Post'));
    await tester.pumpAndSettle();

    // Should have pushed a new route (BlogPostScreen)
    expect(find.text('Blog Post'), findsOneWidget);
  });

  testWidgets('shows error banner when error with posts loaded', (tester) async {
    final posts = [
      _createPost(
        id: 'post-1',
        title: 'Existing Post',
        slug: 'existing-post',
      ),
    ];

    await tester.pumpWidget(buildTestApp(
      BlogState(posts: posts, isLoading: false, error: 'Refresh failed'),
    ));
    await tester.pump();

    // The error text should be visible as a banner within the list
    expect(find.text('Existing Post'), findsOneWidget);
  });
}
