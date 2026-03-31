import 'package:momlaunchpad_mobile/providers/auth_provider.dart';

/// [AuthNotifier] that stays logged out and never schedules [AuthNotifier._checkLoginStatus].
/// Use in widget tests to avoid secure storage and HTTP on startup.
class LoggedOutTestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(isLoggedIn: false, isLoading: false);
  }
}
