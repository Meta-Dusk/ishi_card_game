import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import 'game_components.dart';
import 'package:ishi/models/relic.dart';
import 'package:ishi/models/uno_card.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/socket_service.dart';

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
    _pingSubscription = _socket.messages.listen((message) {
      if (message is LobbyStateMessage && _showPingOverlay) {
        updateUI(() {});
      }
    });
  }

  @override
  void dispose() {
    socketSubscription?.cancel();
    _pingSubscription?.cancel();
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
      playerHand,
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: mainContent),
            _pingToggleButton(),
            if (_showPingOverlay) LivePingPanel(socket: _socket),
          ],
        ),
      ),
    );
  }

  Positioned _pingToggleButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: IconButton(
        icon: Icon(_showPingOverlay ? Icons.close : Icons.network_ping),
        color: Colors.grey.shade800,
        onPressed: () => updateUI(() => _showPingOverlay = !_showPingOverlay),
      ),
    );
  }
}

class LivePingPanel extends StatelessWidget {
  const LivePingPanel({super.key, required this.socket});

  final SocketService socket;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "NETWORK PING",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: .bold,
        ),
      ),
      const Divider(color: Colors.white24),

      // Dynamically build the rows from the SocketService!
      ...socket.playersList.map((player) {
        int ping = player.pingMs;
        Color pingColor = ping < 60
            ? Colors.greenAccent
            : (ping < 150 ? Colors.amber : Colors.redAccent);

        return _playerRow(player, pingColor);
      }),
    ];

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        width: 220,
        padding: const .all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: .circular(12),
          border: .all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: mainContent,
        ),
      ),
    );
  }

  Padding _playerRow(LobbyPlayer player, Color pingColor) {
    final mainContent = [
      Text(
        player.playerName,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      Text(
        "${player.pingMs}ms",
        style: TextStyle(color: pingColor, fontWeight: .bold, fontSize: 13),
      ),
    ];
    return Padding(
      padding: const .only(bottom: 6.0),
      child: Row(mainAxisAlignment: .spaceBetween, children: mainContent),
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
