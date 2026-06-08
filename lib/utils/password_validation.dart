/// Matches backend `binding:"required,min=8"` on registration.
const minPasswordLength = 8;

/// Client-side password check before calling the API.
String? validatePassword(
  String? value, {
  String emptyMessage = 'Please enter a password',
}) {
  if (value == null || value.isEmpty) {
    return emptyMessage;
  }
  if (value.length < minPasswordLength) {
    return 'Password must be at least $minPasswordLength characters';
  }
  return null;
}

String? validateLoginPassword(String? value) =>
    validatePassword(value, emptyMessage: 'Please enter your password');

String? validateRegistrationPassword(String? value) => validatePassword(value);
