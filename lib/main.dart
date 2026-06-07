import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'core/managers/profile_manager.dart';
import 'core/data_types.dart' show isPc;
import 'core/managers/audio_manager.dart';
import 'screens/main_menu/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProfileManager().init();
  await AudioManager().init();
  await Supabase.initialize(
    url: "https://kqcgavmerybqzugmnzri.supabase.co",
    anonKey: "sb_publishable_IKQ4oiW2RC45Yn3l1KJs5w_RJo8IiL0",
  );

  await SystemChrome.setPreferredOrientations([.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(.immersiveSticky);

  if (isPc) {
    await windowManager.ensureInitialized();
    final windowOptions = WindowOptions(center: true, fullScreen: kReleaseMode);
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext _) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainMenuScreen(),
    builder: (_, child) => ExcludeSemantics(child: child),
  );
}
