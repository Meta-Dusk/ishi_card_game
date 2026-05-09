import 'package:flutter/material.dart';
import 'package:ishi/screens/profile_menu.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'game_mode_menu.dart';
import 'lan_setup_menu.dart';
import 'local_setup_menu.dart';
import 'menu_button.dart';

enum MenuState { root, playMode, localSetup, lanSetup, profile }

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
    if (_currentMenu == .playMode || _currentMenu == .profile) {
      _changeMenu(.root);
    } else if (_currentMenu == .localSetup || _currentMenu == .lanSetup) {
      _changeMenu(.playMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      _title(),
      _subtitle(),

      if (_appVersion.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          _appVersion,
          style: TextStyle(
            fontSize: 16,
            fontWeight: .w300,
            color: Colors.grey.shade500,
            letterSpacing: 4,
          ),
        ),
      ],

      const SizedBox(height: 40),

      // THE GAME MENU ANIMATION ENGINE
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: .topCenter,
        child: AnimatedSwitcher(
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
          child: _buildActiveMenu(),
        ),
      ),
    ];

    return _menuHandler(mainContent);
  }

  Widget _title() => Stack(
    children: [
      Text(
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
      ),
      const Text(
        "ISHI",
        style: TextStyle(
          fontSize: 80,
          fontWeight: .w900,
          letterSpacing: 16,
          color: Colors.white,
        ),
      ),
    ],
  );

  Widget _subtitle() => const Text(
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

  PopScope<Object> _menuHandler(List<Widget> mainContent) {
    final scrollView = SingleChildScrollView(
      padding: const .symmetric(vertical: 24, horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(mainAxisAlignment: .center, children: mainContent),
      ),
    );

    return PopScope(
      canPop: _currentMenu == .root, // Only exit app if on Root
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(child: Center(child: scrollView)),
      ),
    );
  }

  // --- MENU ROUTER ---
  Widget _buildActiveMenu() {
    switch (_currentMenu) {
      case .root:
        return _RootMenu(
          key: const ValueKey('root'),
          onPlay: () => _changeMenu(.playMode),
          onProfile: () => _changeMenu(.profile),
          onSettings: () {},
        );
      case .playMode:
        return GameModeMenu(
          key: const ValueKey('playMode'),
          onLocalTap: () => _changeMenu(.localSetup),
          onLanTap: () => _changeMenu(.lanSetup),
          onBack: () => _changeMenu(.root),
        );
      case .localSetup:
        return LocalSetupMenu(
          key: const ValueKey('localSetup'),
          playerCount: _playerCount,
          startingHandSize: _startingHandSize,
          onPlayerCountChanged: (val) => setState(() => _playerCount = val),
          onHandSizeChanged: (val) => setState(() => _startingHandSize = val),
          onBack: () => _changeMenu(.playMode),
        );
      case .lanSetup:
        return LanSetupMenu(
          key: const ValueKey('lanSetup'),
          onBack: () => _changeMenu(.playMode),
        );
      case .profile:
        return ProfileMenu(
          key: const ValueKey('profile'),
          onBack: () => _changeMenu(.root),
        );
    }
  }
}

// ============================================================================
// MENU PANELS
// ============================================================================

class _RootMenu extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const _RootMenu({
    super.key,
    required this.onPlay,
    required this.onSettings,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuButton(
          title: "PLAY",
          icon: Icons.play_arrow_rounded,
          color: Colors.black87,
          isPrimary: true,
          onTap: onPlay,
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "SETTINGS",
          icon: Icons.settings,
          color: Colors.grey.shade800,
          onTap: onSettings,
        ),
        const SizedBox(height: 8),
        MenuButton(
          title: "EDIT PROFILE",
          icon: Icons.person,
          color: Colors.grey.shade800,
          onTap: onProfile,
        ),
      ],
    );
  }
}
