import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/providers/global_logger.dart';

/// A reusable widget that handles Loading, Error, Empty, and Data states
/// for any API call. This provides a consistent UX across the entire app.
///
/// Usage:
/// ```dart
/// final state = ref.watch(myProvider);
/// return ZiroDataView(
///   state: state,
///   onRetry: () => ref.invalidate(myProvider),
///   dataBuilder: (data) => MyWidget(data: data),
/// );
/// ```
class ZiroDataView<T> extends StatelessWidget {
  /// The AsyncValue state from a provider
  final AsyncValue<T> state;

  /// Builder function that receives the data and returns the UI
  final Widget Function(T data) dataBuilder;

  /// Optional callback for retry button
  final VoidCallback? onRetry;

  /// Custom loading widget (default: CircularProgressIndicator)
  final Widget? loadingView;

  /// Custom empty widget (default: icon + message)
  final Widget? emptyView;

  /// Message to display when data is null/empty
  final String? emptyMessage;

  /// Whether to show error stack trace in UI (default: false for production)
  final bool showStackTrace;

  /// Custom error widget builder
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const ZiroDataView({
    super.key,
    required this.state,
    required this.dataBuilder,
    this.onRetry,
    this.loadingView,
    this.emptyView,
    this.emptyMessage,
    this.showStackTrace = false,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (data) => _handleData(context, data),
      error: (error, stackTrace) => _buildErrorState(context, error, stackTrace),
      loading: () => loadingView ?? _buildLoadingState(context),
    );
  }

  Widget _handleData(BuildContext context, T data) {
    // Handle empty collections
    if (data is List && data.isEmpty) {
      return _buildEmptyState(context);
    }

    // Handle nullable types that are null
    if (data == null) {
      return _buildEmptyState(context);
    }

    return dataBuilder(data);
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyView != null) {
      return emptyView!;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'No data found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, StackTrace? stackTrace) {
    // Log error to terminal whenever it's rendered in the UI
    GlobalLogger.log(error, stackTrace, 'ZiroDataView');

    if (errorBuilder != null) {
      return errorBuilder!(error, stackTrace);
    }

    return ZiroErrorView(
      error: error,
      stackTrace: stackTrace,
      onRetry: onRetry,
      showStackTrace: showStackTrace,
    );
  }
}

/// A variant of ZiroDataView that works with nullable types.
/// Returns the builder with null if there's no data.
class ZiroDataViewNullable<T> extends StatelessWidget {
  final AsyncValue<T?> state;
  final Widget Function(T? data) dataBuilder;
  final VoidCallback? onRetry;
  final Widget? loadingView;
  final Widget? emptyView;
  final String? emptyMessage;
  final bool showStackTrace;

  const ZiroDataViewNullable({
    super.key,
    required this.state,
    required this.dataBuilder,
    this.onRetry,
    this.loadingView,
    this.emptyView,
    this.emptyMessage,
    this.showStackTrace = false,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (data) {
        if (data == null) {
          return emptyView ?? _buildEmptyState(context);
        }
        return dataBuilder(data);
      },
      error: (error, stackTrace) => _buildErrorState(context, error, stackTrace),
      loading: () => loadingView ?? const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, StackTrace? stackTrace) {
    // Log error to terminal whenever it's rendered in the UI
    GlobalLogger.log(error, stackTrace, 'ZiroDataViewNullable');

    return ZiroErrorView(
      error: error,
      stackTrace: stackTrace,
      onRetry: onRetry,
      showStackTrace: showStackTrace,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyView != null) return emptyView!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(emptyMessage ?? 'No data', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// A generic error view used across the app to display errors and provide a retry option.
class ZiroErrorView extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool showStackTrace;
  final String? title;

  const ZiroErrorView({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.showStackTrace = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _formatError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (showStackTrace && stackTrace != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stackTrace.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatError(Object error) {
    final errorStr = error.toString();

    if (errorStr.contains('SocketException') || errorStr.contains('Connection')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    if (errorStr.length > 300) {
      return '${errorStr.substring(0, 300)}...';
    }

    return errorStr;
  }
}