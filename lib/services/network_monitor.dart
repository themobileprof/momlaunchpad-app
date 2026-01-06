import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network monitor service
/// Detects network changes and triggers WebSocket reconnection
class NetworkMonitor {
  final WidgetRef _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasConnected = true;

  NetworkMonitor(this._ref);

  /// Start monitoring network connectivity
  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((result) => 
        result != ConnectivityResult.none
      );

      // Network restored after being disconnected
      if (isConnected && !_wasConnected) {
        print('Network restored, attempting to reconnect WebSocket...');
        _reconnectChat();
      }

      _wasConnected = isConnected;
    });
  }

  /// Reconnect chat WebSocket
  void _reconnectChat() async {
    try {
      final chatNotifier = _ref.read(chatProvider.notifier);
      await chatNotifier.connect();
    } catch (e) {
      print('Failed to reconnect after network restore: $e');
    }
  }

  /// Stop monitoring
  void dispose() {
    _subscription?.cancel();
  }
}
