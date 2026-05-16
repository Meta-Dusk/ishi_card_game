import 'package:flutter/material.dart';
import 'package:ishi/core/managers/audio_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/managers/profile_manager.dart';
import 'screens/main_menu/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileManager().init();
  await AudioManager().init();
  await Supabase.initialize(
    url: "https://kqcgavmerybqzugmnzri.supabase.co",
    anonKey: "sb_publishable_IKQ4oiW2RC45Yn3l1KJs5w_RJo8IiL0",
  );
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
