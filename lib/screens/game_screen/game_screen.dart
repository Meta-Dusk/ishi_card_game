import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/dialogs/dev_console_toggle_dialog.dart';
import 'package:ishi/components/overlays/dev_console/dev_console_overlay.dart';
import 'package:ishi/core/audio.dart';
import 'package:ishi/core/managers/audio_manager.dart';
import 'package:ishi/core/managers/dev_console.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/components/dialogs/leave_game_dialog.dart';
import 'package:ishi/components/dialogs/settings_dialog.dart';
import 'package:ishi/components/gameplay/animated_play_button.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/models/relic.dart';
import 'package:ishi/models/uno_card.dart';
import 'game_components.dart';

part 'actions.dart';
part 'network.dart';

class GameScreen extends StatefulWidget {
  final GameManager manager;
  final NetworkService network;

  const GameScreen({super.key, required this.manager, required this.network});

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

  List<IshiCard> _initialHandBuffer = [];

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

    DevConsole().initialize(_manager, _net);
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

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _startOpeningSequence(),
    );
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    _pingSubscription?.cancel();
    _gameEventSubscription?.cancel();
    for (ScrollController controller in scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
    AudioManager().playMusic(Audio.music.menuLoop1);
  }

  @override
  Widget build(BuildContext context) {
    final stackedContent = [
      // Local Player Info & Ping
      Positioned(
        top: 16,
        left: 16,
        child: PingToggleButton(
          showPingOverlay: _showPingOverlay,
          onToggle: () => setState(() => _showPingOverlay = !_showPingOverlay),
          onLongPress: () => showDialog(
            context: context,
            builder: (_) => DevConsoleToggleDialog(
              showDevConsole: _showDevConsoleToggle,
              onChanged: (val) => setState(() => _showDevConsoleToggle = val),
            ),
          ),
        ),
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
        child: TurnIndicator(isMyTurn: isMyTurn),
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
      body: SafeArea(child: Stack(children: stackedContent)),
    );
  }

  // THE PLAY PILE (Center)
  Stack _playPileAndDeck() => Stack(
    alignment: .center,
    clipBehavior: .none,
    children: [
      PlayAndPileDeck(
        manager: _manager,
        onDrawCard: drawCardAction,
        onPlayCard: playCardAction,
        playPileKey: playPileKey,
      ),
      if (_manager.pendingDrawCount > 0)
        Positioned(
          top: -20,
          child: FloatingCombatText(
            key: ValueKey(_manager.pendingDrawCount),
            text: "STACK: +${_manager.pendingDrawCount}!",
          ),
        ),
    ],
  );

  /// LOCAL PLAYER DASHBOARD (Bottom)
  Column _lowerPanel() {
    final animatedCardList = AnimatedCardList(
      animatedListKey: listKeys[localUIIndex],
      currentHand: currentHand,
      selectedCard: _selectedCard,
      onTapCard: (card) {
        if (!isMyTurn) return;
        setState(() {
          if (_selectedCard == card) {
            _selectedCard = null; // Deselect if tapped again
          } else {
            _selectedCard = card; // Select the new card
          }
        });
      },
      scrollController: scrollControllers[localUIIndex],
      isMyTurn: isMyTurn,
    );

    return Column(
      mainAxisSize: .min,
      children: [
        CardCounter(currentHandLength: currentHand.length),
        Opacity(
          opacity: isMyTurn ? 1.0 : 0.5,
          child: HandControls(
            onEndTurn: endTurnAction,
            onFlipAllCard: flipAllCardsAction,
            onSortHand: animatedSort,
            onTakePenalty: takePenaltyAction,
            onToggleAutoSort: () => setState(
              () => _manager.isAutoSortEnabled = !_manager.isAutoSortEnabled,
            ),
            manager: _manager,
            isMyTurn: isMyTurn,
          ),
        ),
        AnimatedPlayButton(
          selectedCard: _selectedCard,
          isMyTurn: isMyTurn,
          onPlay: () => playCardAction(_selectedCard!),
        ),
        Container(
          height: 280,
          padding: const .symmetric(horizontal: 8, vertical: 12),
          child: RawScrollbar(
            key: ValueKey(scrollControllers[localUIIndex]),
            controller: scrollControllers[localUIIndex],
            thumbVisibility: true,
            thumbColor: Colors.black26,
            radius: const .circular(8),
            thickness: 6,
            child: animatedCardList,
          ),
        ),
      ],
    );
  }

  Row _topRightButtonRow(BuildContext context) {
    final buttons = [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const SettingsDialog()
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ),
        icon: const Icon(Icons.settings, color: Colors.white70, size: 30),
        tooltip: "Show Settings",
      ),
      if (_showDevConsoleToggle)
        IconButton(
          onPressed: () => setState(() => _showDevConsole = !_showDevConsole),
          icon: const Icon(Icons.terminal, color: Colors.greenAccent),
          tooltip: "Show Developer Console",
        ),
      IconButton(
        onPressed: _promptLeaveGame,
        icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 30),
        tooltip: "Exit Match",
      ),
    ];
    return Row(mainAxisSize: .min, children: buttons);
  }

  void _promptLeaveGame() => showDialog(
    context: context,
    builder: (_) => LeaveGameDialog(network: _net)
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
  );
}
