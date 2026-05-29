import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/screens/main_menu/main_menu_screen.dart';
import 'package:ishi/services/network_service.dart';
import 'imports/game_components.dart';
import 'imports/game_core.dart';

part 'actions.dart';
part 'network.dart';
part 'events.dart';
part 'relics_handler.dart';
part 'components.dart';
part 'dialogs.dart';

class GameScreen extends StatefulWidget {
  final GameManager manager;
  final NetworkService network;
  final MainMenuScreenState menu;

  const GameScreen({
    super.key,
    required this.manager,
    required this.network,
    required this.menu,
  });

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  // Core
  late GameManager _manager;

  // Network
  NetworkService get _net => widget.network;
  late StreamSubscription? _netSubscription;
  late StreamSubscription? _gameEventSubscription;

  bool _showPingOverlay = false;
  late StreamSubscription? _pingSubscription;
  final playPileKey = GlobalKey<PlayCardsPileState>();

  // UI
  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  AnimatedListState? get getCurrentState =>
      listKeys[localUIIndex]?.currentState;

  bool _showDevConsole = false;
  bool _showDevConsoleToggle = false;
  bool _isViewingRelics = false;
  bool _showSplash = true;

  // Gameplay
  int get localUIIndex => _manager.localPlayerIndex + 1;
  bool get isMyTurn => _manager.currentPlayer == localUIIndex;
  List<IshiCard> get currentHand =>
      _manager.playerHands[_manager.localPlayerIndex];

  IshiCard? _selectedCard;

  Relic? _activeTargetingRelic;
  final List<IshiCard> _relicTargets = [];

  List<IshiCard> _initialHandBuffer = [];

  late Timer _hostTurnTimer;

  List<CombatMessage> _currentCombatMessages = [];
  Key _combatMessagesKey = UniqueKey();
  final List<CombatMessage> _newMessages = [];

  void updateUI(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _startOpeningSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1st Broadcast: Host sends the starting state.
    // Clients receive their cards and instantly start staggering!
    if (_net.isHost) broadcastGameState();

    // Host staggers their own intercepted hand back into the UI
    if (_initialHandBuffer.isNotEmpty) {
      await _staggerDrawCards(_initialHandBuffer);
      _triggerAutoSortIfNeeded();
    }

    // 2nd Broadcast: Tell clients the Host finished dealing.
    if (_net.isHost) broadcastGameState();
  }

  @override
  void initState() {
    super.initState();
    _manager = widget.manager;

    listKeys = {};
    scrollControllers = {};
    for (int i = 1; i <= _manager.playerCount; i++) {
      listKeys[i] = GlobalKey<AnimatedListState>();
      scrollControllers[i] = ScrollController();
    }

    if (_net.isHost && _manager.playerHands.isNotEmpty) {
      _initialHandBuffer = List.from(
        _manager.playerHands[_manager.localPlayerIndex],
      );
      _manager.playerHands[_manager.localPlayerIndex].clear();
    }

    initializeNetworkSync();

    _hostTurnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_net.isHost || _manager.winnerIndex != null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= _manager.turnDeadlineEpoch) {
        updateUI(() => _manager.endTurn());
        broadcastGameState();
      }
    });

    _manager.onChaosTrigger = _onChaosTrigger;
    _manager.onWildBuffTrigger = _onWildBuffTrigger;
    _manager.onEvolvedTrigger = _onEvolvedTrigger;
    _manager.onFrozenTrigger = _onFrozenTrigger;

    DevConsole().initialize(_manager, _net, widget.menu);
    DevConsole().onStateForceSynced = () {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < listKeys.length; i++) {
          listKeys[i] = GlobalKey<AnimatedListState>();
        }
      });
      if (_net.isHost) broadcastGameState();
    };

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioManager().playMusic(Audio.music.gameLoop),
    );
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    _pingSubscription?.cancel();
    _gameEventSubscription?.cancel();
    _hostTurnTimer.cancel();
    for (ScrollController controller in scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
    AudioManager().playMusic(Audio.music.menuLoop);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double responsiveScale = (size.height / 400.0).clamp(0.5, 1.25);

    final mainGameComponents = SafeArea(
      child: Stack(children: _mainGameComponents(size: size)),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: AnimatedGradientBackground(
        colors: [
          Colors.grey,
          Colors.grey.shade600,
          Colors.grey.shade700,
          Colors.grey.shade800,
          Colors.grey.shade900,
        ],
        duration: const Duration(seconds: 12),
        child: _showSplash
            ? Center(child: _splashContent(scale: responsiveScale))
            : mainGameComponents,
      ),
    );
  }

  List<Widget> _mainGameComponents({required Size size}) {
    int animationIndex = 0;

    Duration getAnimationDelay({int interval = 100, int delayAmount = 100}) {
      final currentDelay = delayAmount + (interval * animationIndex);
      animationIndex++;
      return Duration(milliseconds: currentDelay);
    }

    final double responsiveScale = (size.height / 400.0).clamp(0.5, 1.25);

    final turnIndicator = TurnIndicator(
      isMyTurn: isMyTurn,
      turnDeadlineEpoch: _manager.turnDeadlineEpoch,
    );

    final opponentsOverlay = OpponentsOverlay(
      manager: _manager,
      net: _net,
      listKeys: listKeys,
      scale: responsiveScale,
    );

    final playBoardElements = [
      // BACKGROUND HUD (Lowest Z-Index)
      Positioned(
        top: (size.height / 2) - (80 * responsiveScale) - (size.width / 2),
        left: 0,
        right: 0,
        child: Center(
          child: _tableSurface(size: size, responsiveScale: responsiveScale)
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: 0.15, curve: Curves.easeOutCubic),
        ),
      ),

      // MID-GROUND (Opponents & Play Pile)
      Positioned.fill(
        child: opponentsOverlay
            .animate()
            .fadeIn(delay: getAnimationDelay(), duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
      ),
      Positioned(
        top: (size.height / 2) - (128 * responsiveScale),
        left: 0,
        right: 0,
        child: _playPileAndDeck(scale: responsiveScale)
            .animate()
            .fadeIn(delay: getAnimationDelay(), duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
      ),

      // FOREGROUND: Local Player Hand (Highest standard Z-Index)
      Positioned(
        top: (size.height / 2) - (128 * responsiveScale) - 96,
        left: 0,
        right: 0,
        child: turnIndicator
            .animate()
            .fadeIn(delay: getAnimationDelay(), duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
      ),
      Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: PlayerInfo(
          manager: _manager,
          network: _net,
        ).animate().fadeIn(delay: getAnimationDelay(), duration: 400.ms),
      ),
      Align(
        alignment: .bottomCenter,
        child: Transform.scale(
          scale: responsiveScale.clamp(0.5, 1),
          alignment: .bottomCenter,
          child: _lowerPanel
              .animate()
              .fadeIn(delay: getAnimationDelay(), duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 32,
        child: TurnTimeline(manager: _manager, net: _net)
            .animate()
            .fadeIn(delay: getAnimationDelay(), duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
      ),

      // CORNER BUTTONS
      Positioned(
        top: 16,
        left: 16,
        child: _pingToggleButton.animate().fadeIn(
          delay: getAnimationDelay(),
          duration: 400.ms,
        ),
      ),
      Positioned(
        top: 24,
        left: 0,
        right: 0,
        child: Center(
          child: _roundIndicator,
        ).animate().fadeIn(delay: getAnimationDelay(), duration: 400.ms),
      ),
      Positioned(
        top: 16,
        right: 16,
        child: _settingsButton(
          context,
        ).animate().fadeIn(delay: getAnimationDelay(), duration: 400.ms),
      ),

      // CONDITIONAL OVERLAYS (Absolute Top Layer)
      if (_showPingOverlay)
        Positioned(
          top: 64,
          left: 16,
          child: LivePingPanel(network: _net).animate().fadeIn(),
        ),
      if (_showDevConsole)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DevConsoleOverlay(
            onClose: () => setState(() => _showDevConsole = false),
          ).animate().fadeIn(),
        ),
    ];
    return playBoardElements;
  }

  Animate _splashContent({required double scale}) {
    final splashImage = Image.asset(
      Assets.otherIcons.ishiIcon,
      width: 400 * scale.clamp(0.5, 1.0),
    );
    final animatedSplash = splashImage
        .animate(
          onComplete: (_) {
            updateUI(() => _showSplash = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startOpeningSequence();
            });
          },
        )
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .then(delay: 800.ms)
        .fadeOut(duration: 400.ms);
    return animatedSplash;
  }

  void _promptLeaveGame() => showDialog(
    context: context,
    builder: (_) => LeaveGameDialog(network: _net),
  );
}
