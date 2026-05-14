import 'package:flutter/material.dart';
import 'prefs_manager.dart';

final Map<String, Color> avatarColorPalette = {
  'blue': Colors.blue.shade600,
  'red': Colors.red.shade600,
  'green': Colors.green.shade600,
  'orange': Colors.orange.shade600,
  'purple': Colors.purple.shade600,
  'pink': Colors.pink.shade600,
};

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  static const String _defaultPlayerName = "Player";
  static const String _defaultColorName = "blue";

  late String playerName;
  late String avatarColorName;

  Color get avatarColor =>
      avatarColorPalette[avatarColorName] ?? avatarColorPalette['blue']!;

  Color getAvatarColor(String colorName) =>
      avatarColorPalette[colorName] ?? avatarColorPalette['blue']!;

  Future<void> init() async {
    playerName =
        await PrefsManager.getString(.playerName) ?? _defaultPlayerName;
    avatarColorName =
        await PrefsManager.getString(.avatarColorName) ?? _defaultColorName;
  }

  Future<void> saveProfile(String name, String colorName) async {
    await PrefsManager.setString(.playerName, name);
    await PrefsManager.setString(.avatarColorName, colorName);

    playerName = name;
    avatarColorName = colorName;
  }

  Future<void> resetToDefaults() async {
    await PrefsManager.remove(.playerName);
    await PrefsManager.remove(.avatarColorName);

    playerName = _defaultPlayerName;
    avatarColorName = _defaultColorName;
  }
}
