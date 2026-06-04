import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration
class AppConfig {
  static const productionApiUrl = 'https://api.momlaunchpad.com';
  static const productionWsUrl = 'wss://api.momlaunchpad.com';

  /// App UI and API language (English only for now).
  static const String languageCode = 'en';

  /// Initialize environment variables from the bundled `.env` asset.
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Missing or unreadable .env — fallbacks below apply.
    }
  }

  static bool get isProduction => kReleaseMode;

  static String get baseUrl => _resolveHttpBaseUrl();

  static String get wsUrl => _resolveWsUrl(baseUrl);

  /// WebSocket endpoint
  static String get chatWsUrl => '$wsUrl/ws/chat';

  /// OAuth 2.0 Web client ID (must match backend token verification).
  static String get googleWebClientId {
    final fromEnv = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty && !fromEnv.startsWith('your-')) {
      return fromEnv;
    }
    return '270509978456-ul2htboa4prh6g7ci7rje4q0vbpofeko.apps.googleusercontent.com';
  }

  static String _resolveHttpBaseUrl() {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      if (kReleaseMode && _isLocalDevUrl(fromEnv)) {
        return productionApiUrl;
      }
      return fromEnv;
    }
    return kReleaseMode ? productionApiUrl : 'http://localhost:8080';
  }

  static String _resolveWsUrl(String httpBaseUrl) {
    final fromEnv = dotenv.env['WS_BASE_URL']?.trim();
    String url;
    if (fromEnv != null && fromEnv.isNotEmpty) {
      url = kReleaseMode && _isLocalDevUrl(fromEnv) ? productionWsUrl : fromEnv;
    } else {
      url = kReleaseMode ? productionWsUrl : 'ws://localhost:8080';
    }
    return _upgradeWsToMatchHttp(url, httpBaseUrl);
  }

  /// Release builds must not call localhost / LAN IPs from a bundled dev `.env`.
  static bool _isLocalDevUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase();
    if (host == null || host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }
    if (host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.')) {
      return true;
    }
    return false;
  }

  /// Use TLS for WebSockets when the REST API uses HTTPS.
  static String _upgradeWsToMatchHttp(String wsUrl, String httpBaseUrl) {
    final httpScheme = Uri.tryParse(httpBaseUrl)?.scheme;
    if (httpScheme == 'https' && wsUrl.startsWith('ws://')) {
      return wsUrl.replaceFirst('ws://', 'wss://');
    }
    return wsUrl;
  }
}
