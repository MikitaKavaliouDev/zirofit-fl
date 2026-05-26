import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/system_error.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';

class AdminErrorLogsScreen extends ConsumerStatefulWidget {
  const AdminErrorLogsScreen({super.key});

  @override
  ConsumerState<AdminErrorLogsScreen> createState() =>
      _AdminErrorLogsScreenState();
}

class _AdminErrorLogsScreenState extends ConsumerState<AdminErrorLogsScreen> {
  String? _severityFilter;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadErrors());
  }

  void _loadErrors() {
    ref.read(adminProvider.notifier).fetchErrors(
          page: _currentPage,
          limit: _pageSize,
          severity: _severityFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    final errors = state.errors;
    final totalErrors = state.totalErrors;
    final totalPages = _pageSize > 0 ? (totalErrors / _pageSize).ceil() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrors,
          ),
        ],
      ),
      body: Column(
        children: [
          // Severity filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Error', 'error'),
                const SizedBox(width: 8),
                _buildFilterChip('Warning', 'warning'),
                const SizedBox(width: 8),
                _buildFilterChip('Info', 'info'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildBody(theme, state, errors, totalPages),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? severity) {
    final selected = _severityFilter == severity;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _severityFilter = severity;
          _currentPage = 1;
        });
        _loadErrors();
      },
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AdminState state,
    List<SystemError> errors,
    int totalPages,
  ) {
    if (state.isLoading && errors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('No errors found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'All clear! No system errors to display.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        _loadErrors();
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final error = errors[index];
                final dateFormat = DateFormat('MMM d, yyyy HH:mm');

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: _severityColor(error.severity),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error.message,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (error.path != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Path: ${error.path}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            _severityBadge(error.severity, theme),
                            const SizedBox(width: 8),
                            if (error.statusCode != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${error.statusCode}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              dateFormat.format(error.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Pagination
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadErrors();
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: theme.textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadErrors();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _severityBadge(String? severity, ThemeData theme) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        (severity ?? 'unknown').toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
