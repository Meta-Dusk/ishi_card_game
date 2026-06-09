import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, VoidCallback;
import 'package:ishi/core/models/relic/relic.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/core/network/game_state_payload.dart';

part 'events_manager.dart';

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

  /// HOST ONLY: Generates a strictly personalized JSON package
  /// for a specific player.
  GameStatePayload generateGameState(int targetPlayerIndex) => GameStatePayload(
    myPlayerIndex: targetPlayerIndex,
    currentPlayer: currentPlayer,
    direction: isClockwise,
    topCard: discardPile.isNotEmpty ? discardPile.last : null,
    deckSize: deck.length,
    myHand: playerHands[targetPlayerIndex],
    opponentHandSizes: playerHands.map((hand) => hand.length).toList(),
    pendingDrawCount: pendingDrawCount,
    declaredColorIndex: declaredColor?.index,
    actionPoints: actionPoints,
    cardDraws: cardDraws,
    hasPlayedCard: hasPlayedCard,
    hasDrawnCard: hasDrawnCard,
    playerRelics: playerRelics,
    winnerIndex: winnerIndex,
    turnDeadline: turnDeadlineEpoch,
    roundCount: roundCount,
    activeDeckEventIndex: activeDeckEvent.index,
  );

  /// CLIENT ONLY: Takes the typed state payload from
  /// the Host and forces the local UI to match it.
  List<IshiCard> applyGameState(GameStatePayload state) {
    localPlayerIndex = state.myPlayerIndex;
    currentPlayer = state.currentPlayer;
    isClockwise = state.direction;

    if (state.topCard != null) {
      discardPile = [state.topCard!];
    }

    // Deck dummy sync
    if (deck.length != state.deckSize) {
      deck.clear();
      deck.addAll(
        List.generate(
          state.deckSize,
          (i) => IshiCard(id: 'dummy_$i', color: .wild, type: .number),
        ),
      );
    }

    List<IshiCard> newlyDealtCards = [];
    List<IshiCard> incomingHand = state.myHand;
    List<IshiCard> preservedLocalHand = [];

    for (IshiCard localCard in playerHands[localPlayerIndex]) {
      if (incomingHand.any((c) => c.id == localCard.id)) {
        preservedLocalHand.add(localCard);
      }
    }

    for (IshiCard incomingCard in incomingHand) {
      if (!preservedLocalHand.any((c) => c.id == incomingCard.id)) {
        newlyDealtCards.add(incomingCard);
      }
    }

    playerHands[localPlayerIndex] = preservedLocalHand;

    if (opponentHandSizes.isEmpty) {
      opponentHandSizes = state.opponentHandSizes;
      playerHands = List.generate(opponentHandSizes.length, (_) => []);
      playerRelics = List.generate(opponentHandSizes.length, (_) => []);
    } else {
      opponentHandSizes = state.opponentHandSizes;
    }

    pendingDrawCount = state.pendingDrawCount;

    declaredColor = state.declaredColorIndex != null
        ? CardColor.values[state.declaredColorIndex!]
        : null;

    actionPoints = state.actionPoints;
    cardDraws = state.cardDraws;
    hasPlayedCard = state.hasPlayedCard;
    hasDrawnCard = state.hasDrawnCard;
    playerRelics = state.playerRelics;

    if (winnerIndex == null && state.winnerIndex != null) {
      winnerIndex = state.winnerIndex;
      addEvent(.gameOver);
    } else {
      winnerIndex = state.winnerIndex;
    }

    turnDeadlineEpoch = state.turnDeadline;
    roundCount = state.roundCount;
    activeDeckEvent = DeckEventEffect.values[state.activeDeckEventIndex];

    return newlyDealtCards;
  }

  int getCardIndexByPlayerIndex(IshiCard card) =>
      playerHands[currentPlayer - 1].indexOf(card);

  IshiCard? getCardOfCurrentPlayer(IshiCard card) {
    final int playerIndex = currentPlayer - 1;
    final int cardIndex = getCardIndexByPlayerIndex(card);
    if (cardIndex == -1) return null;
    return playerHands[playerIndex][cardIndex];
  }

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

  bool hasValidMoves(int playerIndex) {
    // If they are under attack, they must either deflect or take the penalty
    if (pendingDrawCount > 0) return true;

    final playerAP = actionPoints[playerIndex];
    final playerCD = cardDraws[playerIndex];

    // If they have action points, check if ANY card in their hand is playable
    if (playerAP > 0) {
      for (IshiCard card in playerHands[playerIndex]) {
        if (canPlay(card, playerIndex).canPlay) return true;
      }
    }

    // If they can still draw a card, they have a valid move
    if (playerCD > 0 && deck.isNotEmpty) return true;

    if (playerAP <= 0 && playerCD <= 0) return false;

    // Otherwise, they are completely out of options
    return false;
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

  /// Gets the current active card on the play pile.
  IshiCard get topCard => discardPile.last;

  /// RULE EVALUATION: Can this card be played?
  CanPlayData canPlay(IshiCard card, int playerIndex) {
    final CanPlayData canPlayNoReason = .new(canPlay: true);

    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && card.color == .wild) {
      apCost = 2;
    }
    if (actionPoints[playerIndex] < apCost) {
      return .new(canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (pendingDrawCount > 0) {
      if (card.type == topCard.type) {
        if (card.type == .number) {
          // If a number card caused the attack (like in redCardsBurn),
          // the deflection MUST still be a valid match!
          if (card.color == topCard.color || card.number == topCard.number) {
            return canPlayNoReason;
          }
        } else {
          // +2s and +4s can still stack freely on their own types!
          return canPlayNoReason;
        }
      }

      // DEFLECTION MECHANICS
      bool isNaturalSkip = card.type == .skip;
      bool isBlueFreezeSkip =
          activeDeckEvent == .blueCardsFreeze && card.color == .blue;

      if ((isNaturalSkip || isBlueFreezeSkip) &&
          (topCard.color == .wild || card.color == topCard.color)) {
        return canPlayNoReason;
      }
      return .new(
        canPlay: false,
        reason: "Card cannot deflect incoming attack!",
      );
    }

    if (actionPoints[playerIndex] <= 0) {
      return .new(canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (card.color == .wild) return canPlayNoReason;

    if (activeDeckEvent == .redCardsBurn && card.color == .red) {
      return canPlayNoReason;
    }

    if (declaredColor != null) {
      final isSameColor = card.color == declaredColor;
      return .new(
        canPlay: isSameColor,
        reason: isSameColor ? null : "Card color doesn't match!",
      );
    }

    if (topCard.color == .wild) return canPlayNoReason;
    if (card.color == topCard.color) return canPlayNoReason;

    if (card.type == topCard.type) {
      if (card.type == .number) {
        final isSameNumber = card.number == topCard.number;
        return .new(
          canPlay: isSameNumber,
          reason: isSameNumber ? null : "Card number doesn't match!",
        );
      }
      return canPlayNoReason; // Skips, Reverses, etc. match type
    }
    return .new(canPlay: false, reason: "Invalid card!");
  }

  List<IshiCard> resolvePendingAttack({bool skipHandInsertion = false}) {
    int playerIndex = currentPlayer - 1;
    List<IshiCard> drawnCards = [];

    for (int i = 0; i < pendingDrawCount; i++) {
      if (deck.isEmpty) continue;

      IshiCard card = deck.removeLast();
      drawnCards.add(card);

      // Only insert instantly if the UI isn't handling it
      if (!skipHandInsertion) {
        playerHands[playerIndex].insert(0, card);
      }
    }

    pendingDrawCount = 0;
    actionPoints[playerIndex] = 0; // Force their turn to end
    cardDraws[playerIndex] = 0; // Prevent them from digging for answers
    hasDrawnCard = true;

    // Only sort if we instantly inserted the cards
    if (!skipHandInsertion && playerIndex == localPlayerIndex) {
      sortHand(playerIndex, handSortType);
    }

    return drawnCards;
  }

  /// ACTION: Play a card and apply its effects
  void playCard(int playerIndex, int cardIndex) {
    bool wasUnderAttack = pendingDrawCount > 0;
    IshiCard playedCard = playerHands[playerIndex].removeAt(cardIndex);

    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && playedCard.color == .wild) {
      apCost = 2;
    }
    actionPoints[playerIndex] -= apCost;

    playedCard = _onPlayCardEventEffect(playedCard);

    playedCard.isFaceUp = true;
    discardPile.add(playedCard);
    _applyCardEffect(playedCard);

    hasPlayedCard = true;
    declaredColor = null;
    if (wasUnderAttack) hasDeflected = true;
    if (playerHands[playerIndex].isEmpty) {
      winnerIndex = playerIndex;
      addEvent(.gameOver);
    }
  }

  void setDeclaredColor(CardColor color) => declaredColor = color;

  /// ACTION: Draw a card
  IshiCard drawCard(int playerIndex, {bool skipHandInsertion = false}) {
    cardDraws[playerIndex]--;
    IshiCard drawn = deck.removeLast();

    // Only insert instantly if the UI isn't handling it
    if (!skipHandInsertion) playerHands[playerIndex].insert(0, drawn);

    hasDrawnCard = true;

    // Only auto-sort instantly if we inserted the card instantly
    if (!skipHandInsertion && playerIndex == localPlayerIndex) {
      sortHand(playerIndex, handSortType);
    }

    return drawn;
  }

  /// THE CARD RULES ENGINE\
  /// Also includes some rules reminiscent of Uno.
  void _applyCardEffect(IshiCard playedCard) {
    switch (playedCard.type) {
      case .reverse:
        if (playerCount == 2) {
          _playersToSkip++;
        } else {
          isClockwise = !isClockwise;
          debugPrint(
            "Turn Direction reversed: "
            "${isClockwise ? "clockwise" : "counter-clockwise"}",
          );
        }
        break;
      case .skip:
        if (pendingDrawCount > 0) {
          debugPrint("Player has deflected!");
        } else {
          _playersToSkip++;
          debugPrint("Player has skipped the next player!");
        }
        break;
      case .draw2:
        pendingDrawCount += 2;
        break;
      case .draw4:
        pendingDrawCount += 4;
        break;
      default:
        break;
    }

    _applyActiveDeckEventEffects(playedCard);
  }

  /// Forces a player to draw cards without consuming their CD points
  List<IshiCard> forceDraw(
    int targetPlayerIndex, {
    int count = 1,
    bool skipHandInsertion = false,
  }) {
    List<IshiCard> drawnCards = [];

    for (int i = 0; i < count; i++) {
      if (deck.isEmpty) break;
      IshiCard drawn = deck.removeLast();
      drawnCards.add(drawn);

      // Only insert instantly if the UI isn't handling it
      if (!skipHandInsertion) {
        playerHands[targetPlayerIndex].insert(0, drawn);
      }
    }

    // Only sort instantly if we inserted the cards instantly
    if (!skipHandInsertion && targetPlayerIndex == localPlayerIndex) {
      sortHand(targetPlayerIndex, handSortType);
    }

    return drawnCards;
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

  void endTurn() {
    currentPlayer = getNextPlayer();
    _playersToSkip = 0; // Reset skips after they are consumed

    if (currentPlayer == 1) {
      roundCount++;
      if (onRoundEnd != null) onRoundEnd!();
    }

    final int playerIndex = currentPlayer - 1;

    // Calculate base economies + relic bonuses
    final int bonusAP = playerRelics[playerIndex]
        .where((r) => r.effects[RelicEffect.addActionPoints] != null)
        .fold<int>(
          0,
          (previous, current) =>
              previous + current.effects[RelicEffect.addActionPoints]!,
        );
    final int bonusCD = playerRelics[playerIndex]
        .where((r) => r.effects[RelicEffect.addCardDraws] != null)
        .fold<int>(
          0,
          (previous, current) =>
              previous + current.effects[RelicEffect.addCardDraws]!,
        );

    actionPoints[currentPlayer - 1] = 1 + bonusAP;
    cardDraws[currentPlayer - 1] = 1 + bonusCD;
    hasPlayedCard = false;
    hasDrawnCard = false;
    hasDeflected = false;
    turnDeadlineEpoch = _getTurnDeadlineEpoch;
  }
}
