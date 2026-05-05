import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/events/screens/event_detail_screen.dart';
import 'package:zirofit_fl/features/exercises/screens/exercise_list_screen.dart';
import 'package:zirofit_fl/features/search/providers/global_search_provider.dart';
import 'package:zirofit_fl/features/search/widgets/search_result_tile.dart';

/// Full-screen search that allows users to search across exercises, clients,
/// events, and other content.
///
/// Features:
/// - Auto-focused search text field at the top
/// - Recent searches stored in SharedPreferences
/// - Results grouped into sections by type (Exercises, Clients, Events)
/// - Loading, empty, and error states
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  bool _showRecentSearches = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // Auto-focus the search field after the first frame
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final searches =
        await ref.read(globalSearchProvider.notifier).loadRecentSearches();
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  void _onSearchChanged(String value) {
    ref.read(globalSearchProvider.notifier).search(value);
    setState(() => _showRecentSearches = value.trim().isEmpty);
  }

  void _onSubmitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(globalSearchProvider.notifier).addRecentSearch(trimmed);
    }
  }

  Future<void> _onTapRecentSearch(String query) async {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _onSearchChanged(query);
    await ref.read(globalSearchProvider.notifier).addRecentSearch(query);
  }

  void _onTapResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.exercise:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ExerciseListScreen(),
          ),
        );
      case SearchResultType.client:
        context.go('/trainer/clients/${result.id}');
      case SearchResultType.event:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: result.id),
          ),
        );
      case SearchResultType.trainer:
        context.go('/trainer/profile');
      case SearchResultType.program:
        context.go('/trainer/programs/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search exercises, clients, events...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmitSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(globalSearchProvider.notifier).clearSearch();
                setState(() => _showRecentSearches = true);
                _searchFocusNode.requestFocus();
              },
            ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(GlobalSearchState state, ThemeData theme) {
    // --- Recent searches (visible when query is empty) ---
    if (_showRecentSearches && _recentSearches.isNotEmpty) {
      return _buildRecentSearches(theme);
    }

    // --- Empty query (no results yet, no recent searches) ---
    if (state.query.isEmpty) {
      return _buildEmptyQueryState(theme);
    }

    // --- Loading ---
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- Error ---
    if (state.hasError && state.results.isEmpty) {
      return _buildErrorState(state, theme);
    }

    // --- No results ---
    if (!state.hasResults && !state.isLoading) {
      return _buildNoResultsState(theme);
    }

    // --- Results ---
    return _buildResults(state, theme);
  }

  Widget _buildRecentSearches(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(globalSearchProvider.notifier)
                      .clearRecentSearches();
                  if (mounted) {
                    setState(() => _recentSearches = []);
                  }
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: () => _onTapRecentSearch(query),
                ),
                onTap: () => _onTapRecentSearch(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueryState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Search across exercises, clients, and events',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GlobalSearchState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.error ?? 'An error occurred',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(globalSearchProvider.notifier).search(state.query),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(GlobalSearchState state, ThemeData theme) {
    // Group results by type
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final result in state.results) {
      grouped.putIfAbsent(result.type, () => []).add(result);
    }

    // Type order for display
    const typeOrder = [
      SearchResultType.exercise,
      SearchResultType.client,
      SearchResultType.event,
      SearchResultType.trainer,
      SearchResultType.program,
    ];

    // Type display names
    String typeLabel(SearchResultType t) {
      switch (t) {
        case SearchResultType.exercise:
          return 'Exercises';
        case SearchResultType.client:
          return 'Clients';
        case SearchResultType.event:
          return 'Events';
        case SearchResultType.trainer:
          return 'Trainers';
        case SearchResultType.program:
          return 'Programs';
      }
    }

    final sections = typeOrder
        .where((t) => grouped.containsKey(t) && grouped[t]!.isNotEmpty)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final type = sections[index];
        final items = grouped[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                typeLabel(type),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...items.map(
              (result) => SearchResultTile(
                result: result,
                onTap: () => _onTapResult(result),
              ),
            ),
            if (index < sections.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        );
      },
    );
  }
}
