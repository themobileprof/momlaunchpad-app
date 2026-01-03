import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration
class AppConfig {
  // Initialize environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }
  
  // Detect if running in debug mode
  static bool get isProduction => kReleaseMode;
  
  // Base URLs from .env with fallbacks
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 
      (isProduction ? 'https://api.momlaunchpad.com' : 'http://localhost:8080');
  
  static String get wsUrl => 
      dotenv.env['WS_BASE_URL'] ?? 
      (isProduction ? 'wss://api.momlaunchpad.com' : 'ws://localhost:8080');
  
  // WebSocket endpoint
  static String get chatWsUrl => '$wsUrl/ws/chat';
}
