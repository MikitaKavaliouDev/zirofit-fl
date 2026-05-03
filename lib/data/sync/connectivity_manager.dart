import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and exposes a stream of online/offline state.
class ConnectivityManager {
  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOnline = true;

  /// Stream of connectivity changes. `true` = online, `false` = offline.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity state.
  bool get isOnline => _isOnline;

  ConnectivityManager({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Initialize connectivity monitoring.
  Future<void> initialize() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _isOnline = _evaluateConnectivity(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _evaluateConnectivity(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  /// Manually check current connectivity.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _evaluateConnectivity(results);
    return _isOnline;
  }

  /// Dispose of resources.
  void dispose() {
    _subscription.cancel();
    _controller.close();
  }

  bool _evaluateConnectivity(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every(
      (r) => r == ConnectivityResult.none,
    );
  }
}
