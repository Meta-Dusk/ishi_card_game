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
part 'components.dart';

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
  late GameManager _manager;

  NetworkService get _net => widget.network;
  late StreamSubscription? _netSubscription;
  late StreamSubscription? _gameEventSubscription;

  String? attackMessage;
  Key attackKey = UniqueKey();

  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  bool _showPingOverlay = false;
  late StreamSubscription? _pingSubscription;
  final playPileKey = GlobalKey<PlayCardsPileState>();

  int get localUIIndex => _manager.localPlayerIndex + 1;
  AnimatedListState? get getCurrentState =>
      listKeys[localUIIndex]?.currentState;
  bool get isMyTurn => _manager.currentPlayer == localUIIndex;
  List<IshiCard> get currentHand =>
      _manager.playerHands[_manager.localPlayerIndex];

  IshiCard? _selectedCard;
  bool _showDevConsole = false;
  bool _showDevConsoleToggle = false;
  bool _isViewingRelics = false;

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
    // This causes the face-down cards to instantly pop into the opponent overlay!
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

    AudioManager().playMusic(Audio.music.gameLoop1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOpeningSequence();
    });
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
    AudioManager().playMusic(Audio.music.menuLoop1);
  }

  @override
  Widget build(BuildContext context) {
    final stackedContent = [
      // Ping
      Positioned(top: 16, left: 16, child: _pingToggleButton),

      // Round Indicator
      Positioned(
        top: 24,
        left: 0,
        right: 0,
        child: Center(child: _roundIndicator),
      ),

      // Top Right Settings
      Positioned(top: 16, right: 16, child: _topRightButtonRow(context)),

      // Opponent Hands Overlay
      Positioned(
        top: 64,
        right: 16,
        child: OpponentsOverlay(
          manager: _manager,
          net: _net,
          listKeys: listKeys,
        ),
      ),

      // Game Board
      Positioned(
        top: (MediaQuery.of(context).size.height / 2) - 128,
        left: 0,
        right: 0,
        child: _playPileAndDeck(),
      ),

      // Turn Indicator
      Positioned(
        top: 194,
        left: 0,
        right: 0,
        child: TurnIndicator(
          isMyTurn: isMyTurn,
          turnDeadlineEpoch: _manager.turnDeadlineEpoch,
        ),
      ),

      // Local Hand
      Align(alignment: .bottomCenter, child: _lowerPanel()),

      // Turn Timeline
      Positioned(
        left: 0,
        right: 0,
        bottom: 32,
        child: TurnTimeline(manager: _manager, net: _net),
      ),

      // Overlays
      Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: PlayerInfo(manager: _manager, network: _net),
      ),
      if (_showPingOverlay)
        Positioned(top: 64, left: 16, child: LivePingPanel(network: _net)),
      if (_showDevConsole)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DevConsoleOverlay(
            onClose: () => setState(() => _showDevConsole = false),
          ),
        ),
    ];

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
        child: SafeArea(child: Stack(children: stackedContent)),
      ),
    );
  }

  PingToggleButton get _pingToggleButton => PingToggleButton(
    showPingOverlay: _showPingOverlay,
    onToggle: () => setState(() => _showPingOverlay = !_showPingOverlay),
    onLongPress: () => showDialog(
      context: context,
      builder: (_) => DevConsoleToggleDialog(
        showDevConsole: _showDevConsoleToggle,
        onToggle: (val) => setState(() => _showDevConsoleToggle = val),
      ),
    ),
  );

  Container get _roundIndicator => Container(
    padding: const .symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: .circular(16),
      border: .all(color: Colors.white24, width: 1),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        "ROUND ${_manager.roundCount}",
        key: ValueKey<int>(_manager.roundCount),
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: .bold,
          letterSpacing: 2,
          fontSize: 16,
        ),
      ),
    ),
  );

  void _promptLeaveGame() => showDialog(
    context: context,
    builder: (_) => LeaveGameDialog(network: _net)
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
  );
}
