import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'imports.dart';
import '../settings_menu/settings_menu.dart';
import '../online_multiplayer/online_setup_menu.dart';
import '../profile_menu/profile_menu.dart';
import '../lan_multiplayer/lan_setup_menu.dart';
import '../local_setup_menu.dart';
import 'root_menu.dart';
import 'game_mode_menu.dart';

enum MenuState {
  root,
  playMode,
  localSetup,
  lanSetup,
  onlineSetup,
  profile,
  settings,
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => MainMenuScreenState();
}

class MainMenuScreenState extends State<MainMenuScreen> {
  int _playerCount = 2;
  int _startingHandSize = 7;
  MenuState _currentMenu = .root;
  String _appVersion = '';
  bool showLocalMultiplayer = kDebugMode;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioManager().playMusic(Audio.music.menuLoop),
    );
  }

  void updateUI(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _fetchAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
  }

  Future<void> _changeMenu(MenuState newState) async {
    await AudioManager().playSFX(Audio.sfx.ui.itemSelect);
    setState(() => _currentMenu = newState);
  }

  /// Android Hardware Back Button Handler
  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    switch (_currentMenu) {
      case .playMode:
      case .profile:
      case .settings:
        await _changeMenu(.root);
        break;

      case .localSetup:
      case .lanSetup:
      case .onlineSetup:
        await _changeMenu(.playMode);
        break;

      case .root:
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Exit the app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: .circular(12)),
                ),
                child: Text("Exit"),
              ),
            ],
          ),
        );
        if (shouldExit == true) SystemNavigator.pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey.shade100,
    body: AnimatedGradientBackground(
      colors: [
        Colors.white,
        Colors.white70,
        Colors.grey.withValues(alpha: 0.5),
        Colors.blueGrey.withValues(alpha: 0.25),
        Colors.grey.withValues(alpha: 0.5),
        Colors.white70,
        Colors.white,
      ],
      animationType: .scroll,
      duration: const Duration(seconds: 8),

      child: _showSplash
          ? SequentialSplashAnimator(
              splashes: _splashes,
              onComplete: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : _MenuHandler(
              currentMenu: _currentMenu,
              mainContent: _mainContent,
              onPopInvoked: _onPopInvoked,
            ),
    ),
  );

  List<Widget> get _splashes => [
    Image.asset(Assets.otherIcons.ishiIcon, width: 200),
    const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: "A "),
          TextSpan(
            text: "ROGUELIKE ",
            style: TextStyle(color: Colors.purpleAccent),
          ),
          TextSpan(
            text: "CARD GAME ",
            style: TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
      style: TextStyle(color: Colors.black, fontSize: 24, letterSpacing: 4),
      textAlign: .center,
    ),
    Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        const Text(
          "MADE POSSIBLE WITH",
          style: TextStyle(color: Colors.black, fontSize: 24, letterSpacing: 4),
          textAlign: .center,
        ),
        const SizedBox(height: 8),
        Image.asset(Assets.otherIcons.flutterLogo, width: 200),
      ],
    ),
    const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: "A GAME BY "),
          TextSpan(
            text: "METADUSK",
            style: TextStyle(color: Colors.deepPurple),
          ),
        ],
      ),
      style: TextStyle(color: Colors.black, fontSize: 28, letterSpacing: 4),
      textAlign: .center,
    ),
  ];

  List<Widget> get _mainContent {
    final title = const GameTitle()
        .animate(
          delay: 100.ms,
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
        .tint(color: Colors.black, end: 0.2);

    return [
      title
          .animate()
          .fadeIn(duration: 800.ms, curve: Curves.easeOut)
          .slideY(
            begin: -0.2,
            end: 0,
            duration: 800.ms,
            curve: Curves.easeOutBack,
          ),

      const GameSubtitle()
          .animate(delay: 200.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),

      if (_appVersion.isNotEmpty) ...[
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: .center,
          children: [
            AppVersion(appVersion: _appVersion)
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 1.0, curve: Curves.easeOut),
            if (kDebugMode) ...[
              const SizedBox(width: 8),
              const Text("(debug)", style: TextStyle(color: Colors.blueGrey))
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.5, end: 0.0, curve: Curves.easeOut),
            ],
          ],
        ),
      ],

      const SizedBox(height: 40),

      // THE GAME MENU ANIMATION ENGINE
      AnimatedSize(
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutCubic,
        alignment: .topCenter,
        child: _AnimatedMenuSwitcher(
          currentMenu: _currentMenu,
          localSetupMenu: () => LocalSetupMenu(
            key: const ValueKey('localSetup'),
            playerCount: _playerCount,
            startingHandSize: _startingHandSize,
            onPlayerCountChanged: (val) => setState(() => _playerCount = val),
            onHandSizeChanged: (val) => setState(() => _startingHandSize = val),
            onBack: () => _changeMenu(.playMode),
            menu: this,
          ),
          onChangeMenu: _changeMenu,
          showLocalMultiplayer: showLocalMultiplayer,
          menu: this,
        ),
      ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
    ];
  }
}

class _AnimatedMenuSwitcher extends StatelessWidget {
  final MenuState currentMenu;
  final void Function(MenuState menuState) onChangeMenu;
  final Widget Function() localSetupMenu;
  final bool showLocalMultiplayer;
  final MainMenuScreenState menu;

  const _AnimatedMenuSwitcher({
    required this.currentMenu,
    required this.localSetupMenu,
    required this.onChangeMenu,
    required this.showLocalMultiplayer,
    required this.menu,
  });

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation.drive(Tween<double>(begin: 0.9, end: 1.0)),
        child: child,
      ),
    ),
    child: _ActiveMenu(
      currentMenu: currentMenu,
      onChangeMenu: onChangeMenu,
      localSetupMenu: localSetupMenu,
      showLocalMultiplayer: showLocalMultiplayer,
      menu: menu,
    ),
  );
}

class _ActiveMenu extends StatelessWidget {
  const _ActiveMenu({
    required this.currentMenu,
    required this.onChangeMenu,
    required this.localSetupMenu,
    required this.showLocalMultiplayer,
    required this.menu,
  });

  final MenuState currentMenu;
  final void Function(MenuState) onChangeMenu;
  final Widget Function() localSetupMenu;
  final bool showLocalMultiplayer;
  final MainMenuScreenState menu;

  Widget _buildMenu(MenuState currentMenu) {
    switch (currentMenu) {
      case .root:
        return RootMenu(
          key: const ValueKey('root'),
          onPlay: () => onChangeMenu(.playMode),
          onProfile: () => onChangeMenu(.profile),
          onSettings: () => onChangeMenu(.settings),
        );
      case .playMode:
        return GameModeMenu(
          key: const ValueKey('playMode'),
          onLocalTap: () => onChangeMenu(.localSetup),
          onLanTap: () => onChangeMenu(.lanSetup),
          onOnlineTap: () => onChangeMenu(.onlineSetup),
          onBack: () => onChangeMenu(.root),
          showLocalMultiplayer: showLocalMultiplayer,
        );
      case .localSetup:
        return localSetupMenu();
      case .lanSetup:
        return LanSetupMenu(
          key: const ValueKey('lanSetup'),
          onPrimaryBack: () => onChangeMenu(.playMode),
          onSecondaryBack: (context) => Navigator.pop(context),
          menu: menu,
        );
      case .onlineSetup:
        return OnlineSetupMenu(
          key: const ValueKey('onlineSetup'),
          onPrimaryBack: () => onChangeMenu(.playMode),
          onSecondaryBack: (context) => Navigator.pop(context),
          menu: menu,
        );
      case .profile:
        return ProfileMenu(
          key: const ValueKey('profile'),
          onBack: () => onChangeMenu(.root),
        );
      case .settings:
        return SettingsMenu(
          key: const ValueKey('settings'),
          onBack: () => onChangeMenu(.root),
        );
    }
  }

  @override
  Widget build(BuildContext context) => _buildMenu(currentMenu);
}

class _MenuHandler extends StatelessWidget {
  const _MenuHandler({
    required this.currentMenu,
    required this.mainContent,
    required this.onPopInvoked,
  });

  final MenuState currentMenu;
  final List<Widget> mainContent;
  final void Function(bool isPopped) onPopInvoked;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) => onPopInvoked(didPop),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const .symmetric(vertical: 24, horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisAlignment: .center, children: mainContent),
          ),
        ),
      ),
    ),
  );
}
