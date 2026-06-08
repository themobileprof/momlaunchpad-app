import 'user.dart';

/// Auth response from backend
class AuthResponse {
  final String token;
  final User user;
  final bool isNewUser;

  AuthResponse({
    required this.token,
    required this.user,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'is_new_user': isNewUser,
    };
  }
}
