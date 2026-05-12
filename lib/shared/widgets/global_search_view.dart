import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/theme/theme_colors.dart';
import 'package:zirofit_fl/features/search/providers/global_search_provider.dart';
import 'package:zirofit_fl/features/search/widgets/search_result_tile.dart';

/// Full-screen search overlay matching iOS [GlobalSearchView].
///
/// Displays a search bar with auto-focus, recent searches, and results grouped
/// by type (clients, exercises, trainers, events, programs). Uses the existing
/// [globalSearchProvider] which handles 300ms debounced API search.
///
/// Show as a full-screen modal:
/// ```dart
/// await showDialog(
///   context: context,
///   useSafeArea: false,
///   builder: (_) => const GlobalSearchView(),
/// );
/// ```
class GlobalSearchView extends ConsumerStatefulWidget {
  const GlobalSearchView({super.key});

  @override
  ConsumerState<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends ConsumerState<GlobalSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  bool _showRecentSearches = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
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

  Future<void> _onTapRecentSearch(String query) async {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _onSearchChanged(query);
    await ref.read(globalSearchProvider.notifier).addRecentSearch(query);
  }

  void _onTapResult(SearchResult result) {
    context.pop();
    switch (result.type) {
      case SearchResultType.exercise:
        context.go('/exercises');
      case SearchResultType.client:
        context.go('/trainer/clients/${result.id}');
      case SearchResultType.trainer:
        context.go('/trainer/profile');
      case SearchResultType.event:
        context.go('/events/${result.id}');
      case SearchResultType.program:
        context.go('/trainer/programs/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchProvider);
    final theme = Theme.of(context);
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Search text field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search clients, workouts, exercises...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: themeColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          ref
                              .read(globalSearchProvider.notifier)
                              .addRecentSearch(value.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(child: _buildBody(state, theme, themeColors)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Body content
  // ===========================================================================

  Widget _buildBody(
    GlobalSearchState state,
    ThemeData theme,
    ThemeColors themeColors,
  ) {
    // Recent searches (visible when query is empty)
    if (_showRecentSearches && _recentSearches.isNotEmpty) {
      return _buildRecentSearches(theme, themeColors);
    }

    // Empty query — no results yet, no recent searches
    if (state.query.isEmpty) {
      return _buildEmptyQueryState(theme);
    }

    // Loading
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no results
    if (state.hasError && state.results.isEmpty) {
      return _buildErrorState(state, theme);
    }

    // No results
    if (!state.hasResults && !state.isLoading) {
      return _buildNoResultsState(theme);
    }

    // Results
    return _buildResults(state, theme);
  }

  // ===========================================================================
  // Recent searches
  // ===========================================================================

  Widget _buildRecentSearches(ThemeData theme, ThemeColors themeColors) {
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
                  color: themeColors.textPrimary.withAlpha(179), // 70%
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
                leading: Icon(
                  Icons.history,
                  color: themeColors.textPrimary.withAlpha(128),
                ),
                title: Text(query),
                trailing: Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: themeColors.textPrimary.withAlpha(128),
                ),
                onTap: () => _onTapRecentSearch(query),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Empty query state
  // ===========================================================================

  Widget _buildEmptyQueryState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text(
            'Search across clients, workouts, and exercises',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Error state
  // ===========================================================================

  Widget _buildErrorState(GlobalSearchState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Search failed', style: theme.textTheme.titleMedium),
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

  // ===========================================================================
  // No results state
  // ===========================================================================

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text('No results', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different search term.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Grouped results
  // ===========================================================================

  Widget _buildResults(GlobalSearchState state, ThemeData theme) {
    // Group results by type
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final result in state.results) {
      grouped.putIfAbsent(result.type, () => []).add(result);
    }

    // Display order for result sections
    const typeOrder = [
      SearchResultType.exercise,
      SearchResultType.client,
      SearchResultType.trainer,
      SearchResultType.event,
      SearchResultType.program,
    ];

    String typeLabel(SearchResultType t) {
      switch (t) {
        case SearchResultType.exercise:
          return 'Exercises';
        case SearchResultType.client:
          return 'Clients';
        case SearchResultType.trainer:
          return 'Trainers';
        case SearchResultType.event:
          return 'Events';
        case SearchResultType.program:
          return 'Programs';
      }
    }

    final sections =
        typeOrder
            .where((t) => grouped.containsKey(t) && grouped[t]!.isNotEmpty)
            .toList();

    if (sections.isEmpty) {
      return _buildNoResultsState(theme);
    }

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
