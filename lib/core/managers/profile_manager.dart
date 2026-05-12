import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String playerName = _defaultPlayerName;
  String avatarColorName = _defaultColorName;

  Color get avatarColor =>
      avatarColorPalette[avatarColorName] ?? avatarColorPalette['blue']!;

  Color getAvatarColor(String colorName) =>
      avatarColorPalette[colorName] ?? avatarColorPalette['blue']!;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    playerName = prefs.getString("playerName") ?? _defaultPlayerName;

    avatarColorName = prefs.getString("avatarColorName") ?? _defaultColorName;
  }

  Future<void> saveProfile(String name, String colorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("playerName", name);
    await prefs.setString("avatarColor", colorName);

    playerName = name;
    avatarColorName = colorName;
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("playerName");
    await prefs.remove("avatarColor");

    playerName = _defaultPlayerName;
    avatarColorName = _defaultColorName;
  }
}
