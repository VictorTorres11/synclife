import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
abstract class ConnectivityService {
  /// Check if device is currently online
  Future<bool> get isOnline;

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream;

  /// Dispose resources
  void dispose();
}

/// Implementation of ConnectivityService using connectivity_plus
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl() {
    _connectivity = Connectivity();
    _connectivityController = StreamController<bool>.broadcast();
    _init();
  }

  late final Connectivity _connectivity;
  late final StreamController<bool> _connectivityController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = false;

  void _init() {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = _hasInternetConnection(result);

        // Only emit if status changed
        if (wasOnline != _isOnline) {
          _connectivityController.add(_isOnline);
        }
      },
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _hasInternetConnection(result);
      _connectivityController.add(_isOnline);
    } catch (e) {
      // If we can't check connectivity, assume offline
      _isOnline = false;
      _connectivityController.add(false);
    }
  }

  bool _hasInternetConnection(ConnectivityResult result) {
    // Consider device online if connection type is available (not none)
    return result != ConnectivityResult.none;
  }

  @override
  Future<bool> get isOnline async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _hasInternetConnection(result);
      return _isOnline;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream => _connectivityController.stream;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
