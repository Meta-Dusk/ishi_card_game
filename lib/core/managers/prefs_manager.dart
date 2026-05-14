import 'package:shared_preferences/shared_preferences.dart';

enum PrefsKeys { playerName, avatarColorName }

/// A secure, enum-driven wrapper for SharedPreferences
class PrefsManager {
  static Future<String?> getString(PrefsKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key.name);
  }

  static Future<void> setString(PrefsKeys key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.name, value);
  }

  static Future<void> remove(PrefsKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key.name);
  }
}
