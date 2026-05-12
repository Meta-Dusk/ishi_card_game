import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/screens/game_screen/mini_face_down_card.dart';
import 'package:ishi/screens/game_screen/opponents_overlay.dart';
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
    // --- LOCAL PLAYER DASHBOARD (Bottom) ---
    final lowerPanel = Column(
      mainAxisSize: .min,
      children: [
        CardCounter(currentHandLength: currentHand.length),
        IgnorePointer(
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
            child: AnimatedCardList(
              animatedListKey: listKeys[localUIIndex],
              currentHand: currentHand,
              onTapCard: (card) =>
                  setState(() => card.isFaceUp = !card.isFaceUp),
              scrollController: scrollControllers[localUIIndex],
            ),
          ),
        ),
      ],
    );

    // --- THE PLAY PILE (Center) ---
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

    // --- THE MASTER LAYOUT ---
    final mainContent = [
      // Top Left: Local Player Info & Ping
      Positioned(
        top: 16,
        left: 16,
        width: MediaQuery.of(context).size.width * 0.55,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            PlayerInfo(manager: _manager, network: _net),
            const SizedBox(height: 12),
            PingToggleButton(
              showPingOverlay: _showPingOverlay,
              onToggle: () =>
                  updateUI(() => _showPingOverlay = !_showPingOverlay),
            ),
          ],
        ),
      ),

      // Top Right: The New Opponent Hands Overlay!
      Positioned(
        top: 16,
        right: 16,
        child: OpponentsOverlay(
          manager: _manager,
          net: _net,
          listKeys: listKeys,
        ),
      ),

      // Center: Game Board
      Center(child: playPileAndDeck),

      // Center Text: Turn Indicator
      TurnIndicator(isMyTurn: isMyTurn),

      // Bottom: Local Hand
      Align(alignment: .bottomCenter, child: lowerPanel),

      // Overlays
      if (_showPingOverlay) LivePingPanel(network: _net),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(child: Stack(children: mainContent)),
    );
  }
}

class TurnIndicator extends StatelessWidget {
  const TurnIndicator({super.key, required this.isMyTurn});

  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .center,
      child: Padding(
        padding: const .only(top: 220.0), // Pushed just below the deck
        child: Text(
          isMyTurn ? "YOUR TURN" : "WAITING...",
          style: TextStyle(
            color: isMyTurn ? Colors.greenAccent : Colors.orangeAccent,
            fontSize: 16,
            fontWeight: .bold,
            letterSpacing: 4,
            shadows: const [BoxShadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
