import 'game_mode_menu.dart';
import 'lan_setup_menu.dart';
import 'local_setup_menu.dart';
import 'menu_button.dart';
import 'package:flutter/material.dart';

enum MenuState { root, playMode, localSetup, lanSetup }

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _playerCount = 2;
  int _startingHandSize = 7;

  MenuState _currentMenu = .root;

  void _changeMenu(MenuState newState) =>
      setState(() => _currentMenu = newState);

  /// Android Hardware Back Button Handler
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (_currentMenu == .playMode) {
      _changeMenu(.root);
    } else if (_currentMenu == .localSetup || _currentMenu == .lanSetup) {
      _changeMenu(.playMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      AnimatedContainer(
        alignment: .center,
        duration: const Duration(seconds: 1),
        child: const Text(
          "ISHI: THE UNOLIKE ROGUELIKE",
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          textAlign: .center,
        ),
      ),
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
    }
  }
}

// ============================================================================
// MENU PANELS
// ============================================================================

class _RootMenu extends StatelessWidget {
  final VoidCallback onPlay;
  const _RootMenu({super.key, required this.onPlay});

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
          onTap: () {
            // TODO: Implement Settings
          },
        ),
      ],
    );
  }
}
