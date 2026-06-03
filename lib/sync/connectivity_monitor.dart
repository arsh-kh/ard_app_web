import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity status.
/// Combines connectivity_plus (interface detection) with actual
/// internet reachability checks.
///
/// NOTE: This class is currently unused. The SyncEngine creates its
/// own Connectivity() instance directly. Consider integrating this
/// class into SyncEngine or removing this file.
@Deprecated('Not currently used — SyncEngine has its own connectivity handling')
class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;
  bool _isDisposed = false;

  /// Stream of connectivity status changes.
  Stream<bool> get onStatusChange => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _isOnline;

  /// Initializes the connectivity monitor and starts listening.
  Future<void> initialize() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (error) {
        debugPrint('ConnectivityMonitor error: $error');
        _setOnline(false);
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );
    _setOnline(hasConnection);
  }

  void _setOnline(bool online) {
    if (_isOnline != online && !_isDisposed) {
      _isOnline = online;
      _controller.add(online);
      debugPrint('ConnectivityMonitor: ${online ? "ONLINE" : "OFFLINE"}');
    }
  }

  /// Forces a connectivity check.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );
    _setOnline(hasConnection);
    return _isOnline;
  }

  /// Disposes the monitor and releases resources.
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _controller.close();
  }
}
