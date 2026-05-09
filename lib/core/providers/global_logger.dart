import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global provider observer that logs all provider errors and state changes.
/// Add this to your ProviderScope observers list to enable automatic error logging.
///
/// Example:
/// ```dart
/// ProviderScope(
///   observers: [GlobalLogger()],
///   child: const MyApp(),
/// )
/// ```
class GlobalLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Log async errors (failed API calls, etc.)
    if (newValue is AsyncError) {
      _logProviderError(provider, newValue.error, newValue.stackTrace);
    }

    // Optionally log loading state changes (verbose)
    // if (newValue is AsyncLoading) {
    //   debugPrint('📡 ${provider.name ?? provider.runtimeType}: Loading...');
    // }
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (value is AsyncError) {
      _logProviderError(provider, value.error, value.stackTrace);
    }
  }

  /// Logs an error to the terminal with optional stack trace and context.
  /// Use this for manual logging or from UI components.
  static void log(Object error, [StackTrace? stackTrace, String? context]) {
    final ctx = context != null ? ' [$context]' : '';
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('❌ ERROR$ctx: $error');
    if (stackTrace != null) {
      debugPrint('   Stack: $stackTrace');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logProviderError(ProviderBase<Object?> provider, Object? error, StackTrace? stackTrace) {
    final name = provider.name ?? provider.runtimeType.toString();
    log(error ?? 'Unknown error', stackTrace, 'PROVIDER: $name');
  }
}

/// Extension to make it easier to check for errors in AsyncValue
extension AsyncValueExtension<T> on AsyncValue<T> {
  /// Returns true if this is an error state
  bool get isError => this is AsyncError;

  /// Returns true if this is a loading state
  bool get isLoading => this is AsyncLoading;

  /// Returns true if this has data (not loading, not error)
  bool get hasData => this is AsyncData<T>;

  /// Returns the error if this is an error state, otherwise null
  Object? get errorOrNull => this is AsyncError ? (this as AsyncError).error : null;
}