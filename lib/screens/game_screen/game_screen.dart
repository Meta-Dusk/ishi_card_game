import 'dart:async';
import 'package:esther_gift/core/network_keys.dart';
import 'package:flutter/material.dart';
import 'game_components.dart';
import 'package:esther_gift/core/data_types.dart';
import '../../models/relic.dart';
import '../../models/uno_card.dart';
import '../../managers/game_manager.dart';
import '../../services/socket_service.dart';

part 'actions.dart';
part 'network.dart';

class GameScreen extends StatefulWidget {
  final GameManager manager;

  const GameScreen({super.key, required this.manager});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late GameManager _manager;
  final SocketService _socket = SocketService();
  StreamSubscription? socketSubscription;

  String? attackMessage;
  Key attackKey = UniqueKey();

  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  int get localUIIndex => _manager.localPlayerIndex + 1;
  AnimatedListState? get getCurrentState =>
      listKeys[localUIIndex]?.currentState;
  bool get isMyTurn => _manager.currentPlayer == localUIIndex;
  List<UnoCard> get currentHand =>
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
  }

  @override
  void dispose() {
    socketSubscription?.cancel();
    for (var controller in scrollControllers.values) {
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
          onSortHand: sortHandAction,
          onTakePenalty: takePenaltyAction,
          manager: _manager,
        ),
      ),
    );

    final mainContent = [
      Padding(
        padding: const .all(8.0),
        child: Text(
          isMyTurn ? "YOUR TURN" : "WAITING FOR OPPONENT...",
          style: TextStyle(
            color: isMyTurn ? Colors.green.shade700 : Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      PlayerInfo(manager: _manager),
      const Spacer(),
      playPileAndDeck,
      const Spacer(),
      CardCounter(currentHandLength: currentHand.length),
      handControls,
      Container(
        height: 280,
        padding: const .symmetric(horizontal: 8),
        child: RawScrollbar(
          key: ValueKey(scrollControllers[localUIIndex]),
          controller: scrollControllers[localUIIndex],
          thumbVisibility: true,
          thumbColor: Colors.black26,
          radius: const .circular(8),
          thickness: 6,
          child: animatedList,
        ),
      ),
      const SizedBox(height: 10),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(child: Column(children: mainContent)),
    );
  }
}

class CardCounter extends StatelessWidget {
  const CardCounter({super.key, required this.currentHandLength});
  final int currentHandLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: .circular(20),
        border: .all(color: Colors.white24),
      ),
      child: Text(
        "CARDS IN HAND: $currentHandLength",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: .bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}
