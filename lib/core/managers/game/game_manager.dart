import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, VoidCallback;
import 'package:ishi/core/models/relic/relic.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/core/network/game_state_payload.dart';

part 'game_events.dart';
part 'game_rules.dart';
part 'game_sync.dart';
part 'game_actions.dart';

class CanPlayData {
  CanPlayData({required this.canPlay, this.reason});

  bool canPlay;
  String? reason;
}

enum DeckSortType { byColor, byType, byValue, unsorted }

enum GameManagerEvent { gameOver, deckEventTriggered }

class GameManager {
  // --- CORE STATES ---
  List<IshiCard> deck = [];
  List<IshiCard> discardPile = [];

  /// `playerHands`[`playerIndex`][`cardIndex`]
  late List<List<IshiCard>> playerHands;

  int playerCount;
  int lastDeckTotalIndex = 0;

  // --- ECONOMY STATES ---
  late List<int> actionPoints;
  late List<int> cardDraws;

  /// `playerRelics`[`playerIndex`][`relicIndex`]
  late List<List<Relic>> playerRelics;

  final int startingHandSize;

  // --- TURN STATES ---
  int currentPlayer = 1;
  int pendingDrawCount = 0;
  CardColor? declaredColor;
  int? winnerIndex;

  /// The turn direction.
  bool isClockwise = true;

  /// Stacks if multiple skips are played.
  int _playersToSkip = 0;

  int turnDeadlineEpoch = 0;
  static const int turnDurationSeconds = 60;
  int get _getTurnDeadlineEpoch =>
      DateTime.now().millisecondsSinceEpoch + (turnDurationSeconds * 1000);

  int roundCount = 1;

  // --- ACTION STATES ---
  bool hasPlayedCard = false;
  bool hasDrawnCard = false;
  bool hasDeflected = false;

  // --- NETWORK STATES ---

  /// The Host is always 0. Clients will update this!
  int localPlayerIndex = 0;

  /// Stores the card counts for the UI.
  List<int> opponentHandSizes = [];

  // --- VISUAL STATES ---
  DeckSortType handSortType = .unsorted;
  bool isAutoSortEnabled = false;

  // --- EVENTS ---
  final _eventController = StreamController<GameManagerEvent>.broadcast();
  Stream<GameManagerEvent> get events => _eventController.stream;

  DeckEventEffect activeDeckEvent = .none;
  int pendingEvolutions = 0;
  bool manualTriggerDeckEvent = false;
  final double chaosEffectChance = 0.25;

  /// Gets called once the effect of the deck
  /// event `butterflyEvent` gets triggered.
  VoidCallback? onChaosTrigger;

  /// Gets called once the effect of the deck
  /// event `wildDoubleTrouble` gets triggered.
  VoidCallback? onWildBuffTrigger;

  /// Gets called once the effect of the deck
  /// event `blueCardsFreeze` gets triggered.
  VoidCallback? onFrozenTrigger;

  /// Gets called once the effect of the deck
  /// event `greenCardsEvolution` gets triggered.
  VoidCallback? onEvolvedTrigger;

  /// Gets called once a round ends.
  VoidCallback? onRoundEnd;

  GameManager({
    required this.playerCount,
    required this.startingHandSize,
    this.onChaosTrigger,
    this.onWildBuffTrigger,
    this.onFrozenTrigger,
    this.onEvolvedTrigger,
  });

  void addEvent(GameManagerEvent eventType) => _eventController.add(eventType);

  void dispose() => _eventController.close();

  int getCardIndexByPlayerIndex(IshiCard card) =>
      playerHands[currentPlayer - 1].indexOf(card);

  IshiCard? getCardOfCurrentPlayer(IshiCard card) {
    final int playerIndex = currentPlayer - 1;
    final int cardIndex = getCardIndexByPlayerIndex(card);
    if (cardIndex == -1) return null;
    return playerHands[playerIndex][cardIndex];
  }

  /// Gets the current active card on the play pile.
  IshiCard get topCard => discardPile.last;

  void setDeclaredColor(CardColor color) => declaredColor = color;

  void initializeGame() {
    final generatedDeck = generateStandardDeck();
    deck = generatedDeck.newDeck;
    lastDeckTotalIndex = generatedDeck.lastDeckTotalIndex;
    discardPile.add(deck.removeLast());
    discardPile.last.isFaceUp = true;

    playerHands = List.generate(playerCount, (_) => []);
    actionPoints = List.generate(playerCount, (_) => 1);
    cardDraws = List.generate(playerCount, (_) => 1);
    playerRelics = List.generate(playerCount, (_) => []);

    for (int i = 0; i < startingHandSize; i++) {
      for (int p = 0; p < playerCount; p++) {
        if (deck.isNotEmpty) playerHands[p].add(deck.removeLast());
      }
    }

    turnDeadlineEpoch = _getTurnDeadlineEpoch;
    roundCount = 1;
  }

  void sortHand(int playerIndex, DeckSortType sortType) {
    handSortType = sortType;

    if (sortType == .unsorted) return;

    playerHands[playerIndex].sort((a, b) {
      switch (sortType) {
        case .byColor:
          // 1. Color -> 2. Type -> 3. Number
          int colorComp = a.color.index.compareTo(b.color.index);
          if (colorComp != 0) return colorComp;

          int typeComp = a.type.index.compareTo(b.type.index);
          if (typeComp != 0) return typeComp;

          return (a.number ?? -1).compareTo(b.number ?? -1);

        case .byType:
          // 1. Type -> 2. Number -> 3. Color
          int typeComp = a.type.index.compareTo(b.type.index);
          if (typeComp != 0) return typeComp;

          int numComp = (a.number ?? -1).compareTo(b.number ?? -1);
          if (numComp != 0) return numComp;

          return a.color.index.compareTo(b.color.index);

        case .byValue:
          // 1. Number -> 2. Color -> 3. Type
          //? Note: Action cards (number == null) become -1
          //? and will group neatly together at the front!
          int numComp = (a.number ?? -1).compareTo(b.number ?? -1);
          if (numComp != 0) return numComp;

          int colorComp = a.color.index.compareTo(b.color.index);
          if (colorComp != 0) return colorComp;

          return a.type.index.compareTo(b.type.index);

        case .unsorted:
          return 0;
      }
    });
  }

  /// TURN CALCULATION
  int getNextPlayer() {
    int next = currentPlayer;
    // Calculate steps based on normal turn + any stacked skips
    int steps = 1 + _playersToSkip;

    for (int i = 0; i < steps; i++) {
      if (isClockwise) {
        next++;
        if (next > playerCount) next = 1;
      } else {
        next--;
        if (next < 1) next = playerCount;
      }
    }
    return next;
  }
}
