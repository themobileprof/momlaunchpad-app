import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:momlaunchpad_mobile/config/app_config.dart';

void main() {
  group('AppConfig URL resolution', () {
    tearDown(() {
      dotenv.testLoad(mergeWith: {});
    });

    test('upgrades ws to wss when API is https', () {
      dotenv.testLoad(
        mergeWith: {
          'API_BASE_URL': 'https://api.momlaunchpad.com',
          'WS_BASE_URL': 'ws://api.momlaunchpad.com',
        },
      );

      expect(AppConfig.baseUrl, 'https://api.momlaunchpad.com');
      expect(AppConfig.wsUrl, 'wss://api.momlaunchpad.com');
      expect(AppConfig.chatWsUrl, 'wss://api.momlaunchpad.com/ws/chat');
    });
  });
}
