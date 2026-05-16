import 'package:shared_preferences/shared_preferences.dart';

enum PrefsKeys {
  playerName,
  avatarColorName,
  masterVolume,
  musicVolume,
  sfxVolume,
}

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

  static Future<double?> getDouble(PrefsKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key.name);
  }

  static Future<void> setDouble(PrefsKeys key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key.name, value);
  }

  static Future<void> remove(PrefsKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key.name);
  }
}
