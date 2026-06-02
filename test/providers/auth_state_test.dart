import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/providers/auth_provider.dart';

void main() {
  test('AuthState copyWith preserves error when not specified', () {
    final state = AuthState(error: 'Invalid password');

    final updated = state.copyWith(isLoading: false);

    expect(updated.error, 'Invalid password');
    expect(updated.isLoading, false);
  });

  test('AuthState copyWith clearError removes error', () {
    final state = AuthState(error: 'Invalid password');

    final updated = state.copyWith(clearError: true);

    expect(updated.error, isNull);
  });
}
