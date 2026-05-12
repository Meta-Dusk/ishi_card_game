import 'package:flutter/material.dart';
import 'package:ishi/screens/settings_menu.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _playerCount = 2;
  int _startingHandSize = 7;
  MenuState _currentMenu = .root;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
  }

  void _changeMenu(MenuState newState) =>
      setState(() => _currentMenu = newState);

  /// Android Hardware Back Button Handler
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    switch (_currentMenu) {
      case .playMode:
      case .profile:
      case .settings:
        _changeMenu(.root);
        break;

      case .localSetup:
      case .lanSetup:
      case .onlineSetup:
        _changeMenu(.playMode);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const _GameTitle(),
      const _GameSubtitle(),

      if (_appVersion.isNotEmpty) ...[
        const SizedBox(height: 16),
        _AppVersion(appVersion: _appVersion),
      ],

      const SizedBox(height: 40),

      // THE GAME MENU ANIMATION ENGINE
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
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
          ),
          onChangeMenu: _changeMenu,
        ),
      ),
    ];

    return _MenuHandler(
      currentMenu: _currentMenu,
      mainContent: mainContent,
      onPopInvoked: _onPopInvoked,
    );
  }
}

class _AppVersion extends StatelessWidget {
  const _AppVersion({required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    return Text(
      appVersion,
      style: TextStyle(
        fontSize: 16,
        fontWeight: .w300,
        color: Colors.grey.shade500,
        letterSpacing: 4,
      ),
    );
  }
}

class _GameSubtitle extends StatelessWidget {
  const _GameSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "The Unolike rogulike\ncard game.",
      textAlign: .center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: .w400,
        letterSpacing: 2.5,
        color: Colors.black,
        height: 1.4,
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    final innerText = const Text(
      "ISHI",
      style: TextStyle(
        fontSize: 80,
        fontWeight: .w900,
        letterSpacing: 16,
        color: Colors.white,
      ),
    );

    final outerText = Text(
      "ISHI",
      style: TextStyle(
        fontSize: 80,
        fontWeight: .w900,
        letterSpacing: 16,
        foreground: Paint()
          ..style = .stroke
          ..strokeWidth = 8.0
          ..color = Colors.black,
      ),
    );

    return Stack(children: [outerText, innerText]);
  }
}

class _MenuHandler extends StatelessWidget {
  const _MenuHandler({
    required this.currentMenu,
    required this.mainContent,
    required this.onPopInvoked,
  });

  final MenuState currentMenu;
  final List<Widget> mainContent;
  final void Function(bool) onPopInvoked;

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      padding: const .symmetric(vertical: 24, horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(mainAxisAlignment: .center, children: mainContent),
      ),
    );

    return PopScope(
      canPop: currentMenu == .root, // Only exit app if on Root
      onPopInvokedWithResult: (didPop, _) => onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(child: Center(child: scrollView)),
      ),
    );
  }
}

class _ActiveMenu extends StatelessWidget {
  const _ActiveMenu({
    required this.currentMenu,
    required this.onChangeMenu,
    required this.localSetupMenu,
  });

  final MenuState currentMenu;
  final void Function(MenuState) onChangeMenu;
  final Widget Function() localSetupMenu;

  @override
  Widget build(BuildContext context) {
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
        );
      case .localSetup:
        return localSetupMenu();
      case .lanSetup:
        return LanSetupMenu(
          key: const ValueKey('lanSetup'),
          onBack: () => onChangeMenu(.playMode),
        );
      case .onlineSetup:
        return OnlineSetupMenu(
          key: const ValueKey('onlineSetup'),
          onBack: () => onChangeMenu(.playMode),
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
}

class _AnimatedMenuSwitcher extends StatelessWidget {
  final MenuState currentMenu;
  final void Function(MenuState) onChangeMenu;
  final Widget Function() localSetupMenu;

  const _AnimatedMenuSwitcher({
    required this.currentMenu,
    required this.localSetupMenu,
    required this.onChangeMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(Tween<double>(begin: 0.9, end: 1.0)),
            child: child,
          ),
        );
      },
      child: _ActiveMenu(
        currentMenu: currentMenu,
        onChangeMenu: onChangeMenu,
        localSetupMenu: localSetupMenu,
      ),
    );
  }
}
