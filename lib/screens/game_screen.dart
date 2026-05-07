import 'package:flutter/material.dart';
import '../components/dialogs/color_picker_dialog.dart';
import '../components/floating_combat_text.dart';
import '../components/player_info/player_info.dart';
import '../components/animated_card_list/animated_card_list.dart';
// import '../components/global_modifiers_display.dart';
import '../components/play_and_pile_deck.dart';
import '../components/dialogs/deck_event_dialog.dart';
import '../components/remove_transition.dart';
import '../components/hand_controls.dart';
import '../components/dialogs/chest_dialog.dart';
import '../models/relic.dart';
import '../models/uno_card.dart';
import '../managers/game_manager.dart';
import '../screens/end_of_turn_screen.dart';

class GameScreen extends StatefulWidget {
  final int playerCount;
  final int startingHandSize;

  const GameScreen({
    super.key,
    required this.playerCount,
    required this.startingHandSize,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameManager _manager;
  bool _isPassingDevice = false;
  String? _attackMessage;
  Key _attackKey = UniqueKey();

  /// Starting index at 1 to match player count.
  late Map<int, GlobalKey<AnimatedListState>> _listKeys;

  /// Starting index at 1 to match player count.
  late Map<int, ScrollController> _scrollControllers;

  AnimatedListState? get getCurrentState =>
      _listKeys[_manager.currentPlayer]?.currentState;

  @override
  void initState() {
    super.initState();
    _manager = GameManager(
      playerCount: widget.playerCount,
      startingHandSize: widget.startingHandSize,
    );

    // Initialize UI controllers
    _listKeys = {};
    _scrollControllers = {};
    for (int i = 1; i <= widget.playerCount; i++) {
      _listKeys[i] = GlobalKey<AnimatedListState>();
      _scrollControllers[i] = ScrollController();
    }
  }

  @override
  void dispose() {
    for (int i = 1; i <= _scrollControllers.length; i++) {
      if (_scrollControllers[i] == null) continue;
      _scrollControllers[i]!.dispose();
    }
    super.dispose();
  }

  /// Helper getter to easily access the current player's hand via the manager
  List<UnoCard> get currentHand =>
      _manager.playerHands[_manager.currentPlayer - 1];

  void _drawCard() {
    if (_manager.pendingDrawCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are under attack! Counter it or take the hit!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int playerIndex = _manager.currentPlayer - 1;

    // Check if they have any draws left!
    if (_manager.cardDraws[playerIndex] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have no card draws left this turn!"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_manager.deck.isEmpty) {
      _triggerDeckRestockEvent();
      return;
    }

    setState(() {
      _manager.drawCard(playerIndex);
      final state = getCurrentState;
      state?.insertItem(0, duration: const Duration(milliseconds: 400));
    });
  }

  void _flipAllCards() {
    setState(() {
      final bool anyFaceDown = currentHand.any((card) => card.isFaceDown);
      for (UnoCard card in currentHand) {
        card.isFaceUp = anyFaceDown;
      }
    });
  }

  void _sortHand(bool byColor) {
    setState(() {
      _manager.sortHand(_manager.currentPlayer - 1, byColor: byColor);

      // Regenerate the List Key to force a clean rebuild
      _listKeys[_manager.currentPlayer] = GlobalKey<AnimatedListState>();

      // Temporarily hold the old controller
      final oldController = _scrollControllers[_manager.currentPlayer];

      // Assign a brand new controller so the new list doesn't cause a collision!
      _scrollControllers[_manager.currentPlayer] = ScrollController();

      // Safely dispose of the old controller AFTER the frame renders
      // to prevent memory leaks without crashing the current build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController?.dispose();
      });
    });
  }

  void _endTurn() {
    setState(() {
      final int nextPlayer = _manager.getNextPlayer();

      for (UnoCard card in currentHand) {
        if (nextPlayer == _manager.currentPlayer) break;
        card.isFaceUp = false;
      }

      _attackMessage = null;

      // The 1v1 / Self-Skip Check
      if (nextPlayer == _manager.currentPlayer) {
        // They skipped everyone else and it's their turn again!
        // Instantly process the turn end (to consume skips/refresh AP)
        // without showing the pass screen.
        _manager.endTurn();
        _isPassingDevice = false;
      } else {
        // Normal pass to another player
        _isPassingDevice = true;
      }
    });
  }

  void _takePenalty() {
    setState(() {
      int cardsToDraw = _manager.pendingDrawCount;
      _manager.resolvePendingAttack();

      // Animate the cards flying into the victim's hand
      for (int i = 0; i < cardsToDraw; i++) {
        getCurrentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 400),
        );
      }

      _attackMessage = null;
    });
  }

  void _startNextTurn() {
    setState(() {
      _manager.endTurn();
      _isPassingDevice = false;
    });
  }

  void _playCard(UnoCard card) async {
    final int playerIndex = _manager.currentPlayer - 1;
    final int cardIndex = _manager.getCardIndexByPlayerIndex(card);
    final removedCard = _manager.getCardOfCurrentPlayer(card);

    if (removedCard == null) return;

    setState(() {
      _manager.playCard(playerIndex, cardIndex);

      if (removedCard.type == .draw2 || removedCard.type == .wildDraw4) {
        _attackMessage = "STACK: +${_manager.pendingDrawCount}!";
        _attackKey = UniqueKey();
      }

      // Animate removal from the UI
      final state = getCurrentState;
      state?.removeItem(
        cardIndex,
        (_, animation) =>
            RemoveTransition(removedCard: removedCard, animation: animation),
        duration: const Duration(milliseconds: 300),
      );
    });

    if (removedCard.type == .wild || removedCard.type == .wildDraw4) {
      final CardColor? chosenColor = await showDialog<CardColor>(
        context: context,
        barrierDismissible: false, // Force them to pick!
        builder: (_) => const ColorPickerDialog(),
      );

      if (chosenColor != null) {
        setState(() => _manager.setDeclaredColor(chosenColor));
      }
    } else if (removedCard.type == .chest) {
      // Wait for the player to select a relic from the dialog
      final Relic? chosenRelic = await showDialog<Relic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ChestDialog(),
      );

      if (chosenRelic == null) return;
      setState(() {
        // Add it to their inventory
        _manager.playerRelics[playerIndex].add(chosenRelic);

        // Process immediate effects right now
        if (chosenRelic.effect == .immediateDraw3) {
          for (int i = 0; i < 3; i++) {
            _manager.drawCard(playerIndex);
            getCurrentState?.insertItem(0);
          }
          // Remove it from inventory so it doesn't do anything else
          _manager.playerRelics[playerIndex].remove(chosenRelic);
        }
      });
    }
  }

  void _triggerDeckRestockEvent() {
    setState(() => _manager.deck = generateStandardDeck());

    showDialog(
      context: context,
      barrierDismissible: false, // Forces the player to click the button
      builder: (_) => DeckEventDialog(onDrawCard: _drawCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int nextPlayer = _manager.getNextPlayer();

    // If it's intermission, ONLY show the pass screen to prevent cheating
    if (_isPassingDevice) {
      return EndOfTurnScreen(
        nextPlayer: nextPlayer,
        onStartNextTurn: _startNextTurn,
      );
    }

    final animatedList = AnimatedCardList(
      animatedListKey: _listKeys[_manager.currentPlayer],
      currentHand: currentHand,
      onTapCard: (card) => setState(() => card.isFaceUp = !card.isFaceUp),
      scrollController: _scrollControllers[_manager.currentPlayer],
    );

    final playPileAndDeck = Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        PlayAndPileDeck(
          manager: _manager,
          onDrawCard: _drawCard,
          onPlayCard: (card) => _playCard(card),
        ),
        if (_attackMessage != null)
          Positioned(
            top: -20,
            child: FloatingCombatText(key: _attackKey, text: _attackMessage!),
          ),
      ],
    );

    final handControls = HandControls(
      onEndTurn: _endTurn,
      onFlipAllCard: _flipAllCards,
      onSortHand: _sortHand,
      onTakePenalty: _takePenalty,
      manager: _manager,
    );

    final scrollBar = Container(
      height: 280,
      padding: const .symmetric(horizontal: 8),
      child: RawScrollbar(
        controller: _scrollControllers[_manager.currentPlayer],
        thumbVisibility: true,
        thumbColor: Colors.black26,
        radius: const .circular(8),
        thickness: 6,
        child: animatedList,
      ),
    );

    final cardCounter = CardCounter(currentHandLength: currentHand.length);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // GlobalModifiersDisplay(),
            PlayerInfo(manager: _manager),
            const Spacer(),
            playPileAndDeck,
            const Spacer(),
            cardCounter,
            handControls,
            scrollBar,
            const SizedBox(height: 10),
          ],
        ),
      ),
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
