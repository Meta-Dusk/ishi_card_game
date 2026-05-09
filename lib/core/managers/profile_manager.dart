import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  String playerName = "Player";
  Color avatarColor = Colors.blue.shade600;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    playerName = prefs.getString("playerName") ?? "Player";

    int? colorInt = prefs.getInt("avatarColor");
    if (colorInt == null) return;
    avatarColor = Color(colorInt);
  }

  Future<void> saveProfile(String name, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("playerName", name);
    await prefs.setInt("avatarColor", color.toARGB32());

    playerName = name;
    avatarColor = color;
  }
}
