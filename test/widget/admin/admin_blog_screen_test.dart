import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_blog_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeAdminNotifier extends AdminNotifier {
  final AdminState _overriddenState;

  FakeAdminNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  AdminState get state => _overriddenState;

  @override
  Future<void> fetchBlogPosts() async {}

  @override
  Future<void> createBlogPost(Map<String, dynamic> data) async {}

  @override
  Future<void> deleteBlogPost(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BlogPost _createBlogPost({
  String id = 'post-1',
  String title = 'Test Post',
  String slug = 'test-post',
  String content = 'Content here',
  String? excerpt = 'Excerpt here',
  bool published = true,
  String authorId = 'author-1',
}) {
  return BlogPost(
    id: id,
    title: title,
    slug: slug,
    content: content,
    excerpt: excerpt,
    published: published,
    authorId: authorId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpApp(
      const AdminBlogScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when error state with no posts', (tester) async {
    await tester.pumpApp(
      const AdminBlogScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(error: 'Something went wrong'),
            )),
      ],
    );
    await tester.pump();

    // Error is not displayed in this screen, but empty state should appear
    expect(find.text('No blog posts'), findsOneWidget);
    expect(find.text('Create Post'), findsOneWidget);
    // Ensure loading indicator is not shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows blog posts when data loaded', (tester) async {
    final posts = [
      _createBlogPost(id: 'post-1', title: 'First Post', published: true),
      _createBlogPost(id: 'post-2', title: 'Second Post', published: false),
    ];

    await tester.pumpApp(
      const AdminBlogScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(blogPosts: posts, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('First Post'), findsOneWidget);
    expect(find.text('Second Post'), findsOneWidget);
    // Check for published/draft badges
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('shows empty state when no blog posts', (tester) async {
    await tester.pumpApp(
      const AdminBlogScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(blogPosts: [], isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No blog posts'), findsOneWidget);
    expect(find.text('Create Post'), findsOneWidget);
  });
}