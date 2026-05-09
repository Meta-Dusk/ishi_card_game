import 'package:flutter/material.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'screens/main_menu/main_menu_screen.dart';

void main() async {
  await ProfileManager().init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
