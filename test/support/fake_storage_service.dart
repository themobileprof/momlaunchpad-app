import 'package:momlaunchpad_mobile/services/storage_service.dart';

/// In-memory [StorageService] for tests (no platform secure storage).
class FakeStorageService extends StorageService {
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _languageKey = 'language';

  final Map<String, String> _mem = {};

  @override
  Future<String?> getToken() async => _mem[_tokenKey];

  @override
  Future<void> saveToken(String token) async {
    _mem[_tokenKey] = token;
  }

  @override
  Future<void> deleteToken() async {
    _mem.remove(_tokenKey);
  }

  @override
  Future<String?> getUserId() async => _mem[_userIdKey];

  @override
  Future<void> saveUserId(String userId) async {
    _mem[_userIdKey] = userId;
  }

  @override
  Future<String?> getLanguage() async => _mem[_languageKey];

  @override
  Future<void> saveLanguage(String language) async {
    _mem[_languageKey] = language;
  }

  @override
  Future<void> clearAll() async => _mem.clear();

  @override
  Future<bool> isLoggedIn() async {
    final t = _mem[_tokenKey];
    return t != null && t.isNotEmpty;
  }
}
