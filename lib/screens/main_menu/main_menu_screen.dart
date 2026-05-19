import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ishi/components/text/app_version.dart';
import 'package:ishi/components/text/game_subtitle.dart';
import 'package:ishi/components/text/game_title.dart';
import 'package:ishi/core/audio.dart';
import 'package:ishi/core/managers/audio_manager.dart';
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

  Future<void> _changeMenu(MenuState newState) async {
    await AudioManager().playSFX(Audio.sfx.itemSelect);
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

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => _MenuHandler(
    currentMenu: _currentMenu,
    mainContent: _mainContent,
    onPopInvoked: _onPopInvoked,
  );

  List<Widget> get _mainContent => [
    const GameTitle()
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
        .tint(color: Colors.black, end: 0.2),

    const GameSubtitle(),

    if (_appVersion.isNotEmpty) ...[
      const SizedBox(height: 16),
      AppVersion(appVersion: _appVersion)
          .animate()
          .fadeIn(delay: 600.ms)
          .slideY(begin: 1.0, curve: Curves.easeOut),
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
        ),
        onChangeMenu: _changeMenu,
      ),
    ),
  ];
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
  Widget build(BuildContext context) => PopScope(
    canPop: currentMenu == .root, // Only exit app if on Root
    onPopInvokedWithResult: (didPop, _) => onPopInvoked(didPop),
    child: Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(child: Center(child: _scrollView())),
    ),
  );

  SingleChildScrollView _scrollView() => SingleChildScrollView(
    padding: const .symmetric(vertical: 24, horizontal: 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(mainAxisAlignment: .center, children: mainContent),
    ),
  );
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

  Widget _buildMenu(MenuState currentMenu) {
    switch (currentMenu) {
      case .root:
        AudioManager().playMusic(Audio.music.menuLoop1);
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
          onPrimaryBack: () => onChangeMenu(.playMode),
          onSecondaryBack: (context) => Navigator.pop(context),
        );
      case .onlineSetup:
        return OnlineSetupMenu(
          key: const ValueKey('onlineSetup'),
          onPrimaryBack: () => onChangeMenu(.playMode),
          onSecondaryBack: (context) => Navigator.pop(context),
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
    ),
  );
}
