import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  static const String _defaultPlayerName = "Player";
  static const int _defaultAvatarColor = 0x1FBFFF;

  String playerName = _defaultPlayerName;
  Color avatarColor = Color(_defaultAvatarColor);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    playerName = prefs.getString("playerName") ?? _defaultPlayerName;

    int? colorInt = prefs.getInt("avatarColor") ?? _defaultAvatarColor;
    avatarColor = Color(colorInt);
  }

  Future<void> saveProfile(String name, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("playerName", name);
    await prefs.setInt("avatarColor", color.toARGB32());

    playerName = name;
    avatarColor = Color(color.toARGB32());
  }
}
