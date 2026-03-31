import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads a static env map so [AppConfig] works in tests without a real `.env` file.
void loadTestEnv() {
  dotenv.testLoad(
    mergeWith: {
      'API_BASE_URL': 'http://127.0.0.1:9',
      'WS_BASE_URL': 'ws://127.0.0.1:9',
    },
  );
}
