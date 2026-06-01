import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

/// Secure storage service for JWT tokens and sensitive data
class StorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _languageKey = 'language';
  static const String _cachedUserKey = 'cached_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Store JWT token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Remove JWT token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Store user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Store user language preference
  Future<void> saveLanguage(String language) async {
    await _storage.write(key: _languageKey, value: language);
  }

  /// Get stored language preference
  Future<String?> getLanguage() async {
    return await _storage.read(key: _languageKey);
  }

  /// Cache the signed-in user for offline session restore.
  Future<void> saveCachedUser(User user) async {
    await _storage.write(key: _cachedUserKey, value: jsonEncode(user.toJson()));
  }

  /// Last known user profile (used when the network is unavailable on startup).
  Future<User?> getCachedUser() async {
    final raw = await _storage.read(key: _cachedUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
