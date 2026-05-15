import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/core/managers/game_manager.dart';
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
  StreamSubscription? _netSubscription;

  String? attackMessage;
  Key attackKey = UniqueKey();

  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  bool _showPingOverlay = false;
  StreamSubscription? _pingSubscription;
  final playPileKey = GlobalKey<PlayCardsPileState>();

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
        Opacity(
          opacity: isMyTurn ? 1.0 : 0.5,
          child: HandControls(
            onEndTurn: endTurnAction,
            onFlipAllCard: flipAllCardsAction,
            onSortHand: animatedSort,
            onTakePenalty: takePenaltyAction,
            manager: _manager,
            isMyTurn: isMyTurn,
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
              isMyTurn: isMyTurn,
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

    // --- THE MASTER LAYOUT ---
    final stackedContent = [
      // Top Left: Local Player Info & Ping
      Positioned(
        top: 16,
        left: 16,
        child: PingToggleButton(
          showPingOverlay: _showPingOverlay,
          onToggle: () => updateUI(() => _showPingOverlay = !_showPingOverlay),
        ),
      ),

      // Leave Button
      Positioned(
        top: 16,
        right: 16,
        child: IconButton(
          onPressed: _promptLeaveGame,
          icon: const Icon(
            Icons.exit_to_app,
            color: Colors.redAccent,
            size: 30,
          ),
          tooltip: "Exit game?",
        ),
      ),

      // Top Right: Opponent Hands Overlay
      Positioned(
        top: 64,
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
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 245,
        child: TurnIndicator(isMyTurn: isMyTurn),
      ),

      // Bottom: Local Hand
      Align(alignment: .bottomCenter, child: lowerPanel),

      // Overlays
      Positioned(
        top: 0,
        bottom: 0,
        left: 8,
        right: 0,
        child: PlayerInfo(manager: _manager, network: _net),
      ),
      if (_showPingOverlay)
        Positioned(top: 64, left: 16, child: LivePingPanel(network: _net)),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(child: Stack(children: stackedContent)),
    );
  }

  void _promptLeaveGame() => showDialog(
    context: context,
    builder: (_) => LeaveGameDialog(network: _net),
  );
}

class LeaveGameDialog extends StatelessWidget {
  const LeaveGameDialog({super.key, required this.network});

  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text("Leave Game", style: TextStyle(color: Colors.white)),
      content: const Text(
        "Are you sure you want to leave the match?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await network.disconnect(); // Alert peers
            if (!context.mounted) return;
            // Back to Main Menu
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text("LEAVE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
