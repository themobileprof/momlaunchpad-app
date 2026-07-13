import 'package:shared_preferences/shared_preferences.dart';
import '../models/baby_gender.dart';
import '../models/user_profile.dart';

const _storagePrefix = 'user_baby_gender_';

String _storageKey(String userId) => '$_storagePrefix$userId';

Future<BabyGender?> loadStoredBabyGender(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return BabyGender.fromApi(prefs.getString(_storageKey(userId)));
}

Future<void> saveStoredBabyGender(
  String userId,
  BabyGender? gender,
) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _storageKey(userId);
  if (gender == null) {
    await prefs.remove(key);
  } else {
    await prefs.setString(key, gender.apiValue);
  }
}

Future<UserProfile> mergeProfileBabyGender(
  String userId,
  UserProfile profile,
) async {
  if (profile.babyGender != null) {
    await saveStoredBabyGender(userId, profile.babyGender);
    return profile;
  }
  final stored = await loadStoredBabyGender(userId);
  if (stored != null) {
    return profile.copyWith(babyGender: stored);
  }
  return profile;
}
