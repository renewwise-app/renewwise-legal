import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/repository/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<bool?> getBool(String key) async => (await _prefs).getBool(key);

  @override
  Future<int?> getInt(String key) async => (await _prefs).getInt(key);

  @override
  Future<String?> getString(String key) async => (await _prefs).getString(key);

  @override
  Future<bool> containsKey(String key) async =>
      (await _prefs).containsKey(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await (await _prefs).setBool(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await (await _prefs).setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _prefs).setString(key, value);
  }
}
