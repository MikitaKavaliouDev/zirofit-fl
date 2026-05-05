import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/search/providers/global_search_provider.dart';

/// A Material ListTile styled for global search results with an icon
/// determined by the result type.
class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _backgroundColor(theme),
        child: Icon(
          _iconForType(result.type),
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        result.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  IconData _iconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.exercise:
        return Icons.fitness_center;
      case SearchResultType.client:
        return Icons.person;
      case SearchResultType.trainer:
        return Icons.school;
      case SearchResultType.event:
        return Icons.event;
      case SearchResultType.program:
        return Icons.assignment;
    }
  }

  Color _backgroundColor(ThemeData theme) {
    switch (result.type) {
      case SearchResultType.exercise:
        return theme.colorScheme.primaryContainer;
      case SearchResultType.client:
        return theme.colorScheme.tertiaryContainer;
      case SearchResultType.trainer:
        return theme.colorScheme.secondaryContainer;
      case SearchResultType.event:
        return theme.colorScheme.surfaceContainerHighest;
      case SearchResultType.program:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}
