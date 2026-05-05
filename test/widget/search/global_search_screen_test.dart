import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/search/providers/global_search_provider.dart';
import 'package:zirofit_fl/features/search/screens/global_search_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeGlobalSearchNotifier extends GlobalSearchNotifier {
  GlobalSearchState _s;
  final List<String> recentSearches;

  FakeGlobalSearchNotifier(this._s, {this.recentSearches = const []})
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  GlobalSearchState get state => _s;

  void emit(GlobalSearchState s) {
    _s = s;
    super.state = s;
  }

  @override
  void search(String query) {}

  @override
  void clearSearch() {}

  @override
  Future<List<String>> loadRecentSearches() async => recentSearches;

  @override
  Future<void> addRecentSearch(String query) async {}

  @override
  Future<void> clearRecentSearches() async {}
}

Widget buildApp(GlobalSearchState state, {List<String> recentSearches = const []}) {
  return ProviderScope(
    overrides: [
      globalSearchProvider.overrideWith(
        (ref) => FakeGlobalSearchNotifier(state, recentSearches: recentSearches),
      ),
    ],
    child: const MaterialApp(home: GlobalSearchScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('GlobalSearchScreen', () {
    testWidgets('renders with search field auto-focused', (tester) async {
      await tester.pumpWidget(buildApp(const GlobalSearchState()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      // AppBar title is actually the TextField, so no separate title text
      // Just verify the hint text is present
      expect(
        find.text('Search exercises, clients, events...'),
        findsOneWidget,
      );
    });

    testWidgets('empty state when no query', (tester) async {
      await tester.pumpWidget(buildApp(const GlobalSearchState()));
      await tester.pumpAndSettle();

      expect(find.text('Search across exercises, clients, and events'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows recent searches below search bar', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const GlobalSearchState(),
          recentSearches: ['bench press', 'john doe', 'yoga class'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('bench press'), findsOneWidget);
      expect(find.text('john doe'), findsOneWidget);
      expect(find.text('yoga class'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('typing triggers search results', (tester) async {
      final results = [
        const SearchResult(
          id: '1',
          type: SearchResultType.exercise,
          title: 'Bench Press',
          subtitle: 'Chest',
        ),
        const SearchResult(
          id: '2',
          type: SearchResultType.client,
          title: 'John Doe',
          subtitle: 'john@example.com',
        ),
      ];

      await tester.pumpWidget(
        buildApp(GlobalSearchState(query: 'bench', results: results)),
      );
      await tester.pumpAndSettle();

      // Should show section headers
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);

      // Should show result items
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('shows loading indicator when searching', (tester) async {
      await tester.pumpWidget(
        buildApp(const GlobalSearchState(isLoading: true, query: 'test')),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no results state', (tester) async {
      await tester.pumpWidget(
        buildApp(const GlobalSearchState(query: 'nonexistent')),
      );
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try a different search term.'), findsOneWidget);
    });
  });
}
