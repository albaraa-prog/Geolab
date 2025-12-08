import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = result.isNotEmpty && result.first != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _isConnected =
          results.isNotEmpty && results.first != ConnectivityResult.none;

    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isConnected =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {

      _isConnected = false;
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
