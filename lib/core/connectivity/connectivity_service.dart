import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = false;

  ConnectivityService() {
    _init();
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get isOnline => _isOnline;

  Future<void> _init() async {
    // Initial check
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);

    // Listen to changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final forceOffline = prefs.getBool('force_offline') ?? false;

    if (forceOffline) {
      _isOnline = false;
    } else {
      // Check if ANY of the results means we are connected
      _isOnline = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );
    }

    _controller.add(_isOnline);
  }

  void dispose() {
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
