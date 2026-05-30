import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

enum AppThemePreference {
  light,
  dark,
  system;

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
      case AppThemePreference.system:
        return 'System';
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
      case AppThemePreference.system:
        return 'system';
    }
  }

  static AppThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }
}

class ThemeNotifier extends Notifier<AppThemePreference> {
  @override
  AppThemePreference build() {
    _load();
    return AppThemePreference.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppThemePreference.fromStorage(prefs.getString(_themeModeKey));
  }

  Future<void> setPreference(AppThemePreference preference) async {
    state = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, preference.storageValue);
  }
}

final themePreferenceProvider =
    NotifierProvider<ThemeNotifier, AppThemePreference>(ThemeNotifier.new);
