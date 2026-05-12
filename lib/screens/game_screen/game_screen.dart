import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/models/relic.dart';
import 'package:ishi/models/uno_card.dart';
import 'game_components.dart';
import 'card_counter.dart';
import 'live_ping_panel.dart';
import 'ping_toggle_button.dart';

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
  StreamSubscription? _netSubscription;

  String? attackMessage;
  Key attackKey = UniqueKey();

  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  bool _showPingOverlay = false;
  StreamSubscription? _pingSubscription;

  int get localUIIndex => _manager.localPlayerIndex + 1;

  AnimatedListState? get getCurrentState =>
      listKeys[localUIIndex]?.currentState;

  bool get isMyTurn => _manager.currentPlayer == localUIIndex;

  List<IshiCard> get currentHand =>
      _manager.playerHands[_manager.localPlayerIndex];

  void updateUI(VoidCallback fn) {
    if (mounted) setState(fn);
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

    initializeNetworkSync();

    // This safely rebuilds ONLY the overlay when new pings arrive
    _pingSubscription = _net.messages.listen((message) {
      if (message is LobbyStateMessage && _showPingOverlay) {
        updateUI(() {});
      }
    });
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    _pingSubscription?.cancel();
    for (ScrollController controller in scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animatedList = AnimatedCardList(
      animatedListKey: listKeys[localUIIndex],
      currentHand: currentHand,
      onTapCard: (card) => setState(() => card.isFaceUp = !card.isFaceUp),
      scrollController: scrollControllers[localUIIndex],
    );

    final playPileAndDeck = Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        PlayAndPileDeck(
          manager: _manager,
          onDrawCard: drawCardAction,
          onPlayCard: playCardAction,
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

    final handControls = IgnorePointer(
      ignoring: !isMyTurn,
      child: Opacity(
        opacity: isMyTurn ? 1.0 : 0.5,
        child: HandControls(
          onEndTurn: endTurnAction,
          onFlipAllCard: flipAllCardsAction,
          onSortHand: animatedSort,
          onTakePenalty: takePenaltyAction,
          manager: _manager,
        ),
      ),
    );

    final playerHand = Container(
      height: 280,
      padding: const .symmetric(horizontal: 8, vertical: 12),
      child: RawScrollbar(
        key: ValueKey(scrollControllers[localUIIndex]),
        controller: scrollControllers[localUIIndex],
        thumbVisibility: true,
        thumbColor: Colors.black26,
        radius: const .circular(8),
        thickness: 6,
        child: animatedList,
      ),
    );

    final mainContent = [
      Padding(
        padding: const .all(8.0),
        child: Text(
          isMyTurn ? "YOUR TURN" : "WAITING FOR OPPONENT...",
          style: TextStyle(
            color: isMyTurn ? Colors.green.shade700 : Colors.orangeAccent,
            fontWeight: .bold,
            letterSpacing: 2,
          ),
        ),
      ),
      PlayerInfo(manager: _manager, network: _net),
      const Spacer(),
      playPileAndDeck,
      const Spacer(),
      CardCounter(currentHandLength: currentHand.length),
      handControls,
      playerHand,
    ];

    final stackedContent = [
      Column(children: mainContent),
      PingToggleButton(
        showPingOverlay: _showPingOverlay,
        onToggle: () => updateUI(() => _showPingOverlay = !_showPingOverlay),
      ),
      if (_showPingOverlay) LivePingPanel(network: _net),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(child: Stack(children: stackedContent)),
    );
  }
}
