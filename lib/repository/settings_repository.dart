/// Low-level persistence boundary for app settings (SharedPreferences keys).
abstract class SettingsRepository {
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<String?> getString(String key);
  Future<bool> containsKey(String key);

  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
}
