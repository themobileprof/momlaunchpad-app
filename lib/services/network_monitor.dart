import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';

/// Network monitor service
/// Detects network changes and triggers WebSocket reconnection
class NetworkMonitor {
  final WidgetRef _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasConnected = true;
  Timer? _reconnectTimer;
  DateTime? _lastReconnectAttempt;

  NetworkMonitor(this._ref);

  /// Start monitoring network connectivity
  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((result) => 
        result != ConnectivityResult.none
      );

      // Network restored after being disconnected
      if (isConnected && !_wasConnected) {
        debugPrint('Network restored, scheduling reconnect...');
        _scheduleReconnect();
      }

      _wasConnected = isConnected;
    });
  }

  /// Schedule reconnection with debouncing (wait 10 seconds minimum)
  void _scheduleReconnect() {
    // Cancel any pending reconnect
    _reconnectTimer?.cancel();

    // Don't reconnect if we just tried recently
    if (_lastReconnectAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastReconnectAttempt!);
      if (timeSinceLastAttempt < const Duration(seconds: 10)) {
        debugPrint('Skipping reconnect - too soon (${timeSinceLastAttempt.inSeconds}s ago)');
        return;
      }
    }

    // Wait 10 seconds before attempting reconnect
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      _reconnectChat();
    });
  }

  /// Reconnect chat WebSocket
  Future<void> _reconnectChat() async {
    _lastReconnectAttempt = DateTime.now();
    try {
      final chatNotifier = _ref.read(chatProvider.notifier);
      await chatNotifier.connect();
    } catch (e) {
      debugPrint('Failed to reconnect after network restore: $e');
    }
  }

  /// Stop monitoring
  void dispose() {
    _subscription?.cancel();
    _reconnectTimer?.cancel();
  }
}
