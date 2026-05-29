import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, VoidCallback;
import 'package:ishi/core/data_types.dart';
import 'package:ishi/core/models/relic/relic.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/deck_event.dart';

part 'events_manager.dart';

typedef CanPlayRecord = ({bool canPlay, String? reason});

enum DeckSortType { byColor, byType, byValue, unsorted }

class _BoardKeys {
  static const String myPlayerIndex = 'myPlayerIndex';
  static const String currentPlayer = 'currentPlayer';
  static const String direction = 'direction';
  static const String topCard = 'topCard';
  static const String deckSize = 'deckSize';
  static const String myHand = 'myHand';
  static const String opponentHandSizes = 'opponentHandSizes';
  static const String pendingDrawCount = 'pendingDrawCount';
  static const String declaredColor = 'declaredColor';
  static const String actionPoints = 'actionPoints';
  static const String cardDraws = 'cardDraws';
  static const String hasPlayedCard = 'hasPlayedCard';
  static const String hasDrawnCard = 'hasDrawnCard';
  static const String playerRelics = 'playerRelics';
  static const String winnerIndex = 'winnerIndex';
  static const String turnDeadline = 'turnDeadline';
  static const String roundCount = 'roundCount';
  static const String activeDeckEvent = 'activeDeckEvent';
}

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

  /// HOST ONLY: Generates a strictly personalized JSON package for a specific player.
  StringDynamicMap generateGameStateJson(int targetPlayerIndex) {
    // Calculate how many cards everyone else has
    List<int> handSizes = [];
    for (int i = 0; i < playerHands.length; i++) {
      handSizes.add(playerHands[i].length);
    }

    // Safely grab the top card
    StringDynamicMap? topCardJson;
    if (discardPile.isNotEmpty) topCardJson = discardPile.last.toJson();

    // Serialize ONLY the target player's hand!
    List<StringDynamicMap> myHandJson = playerHands[targetPlayerIndex]
        .map((card) => card.toJson())
        .toList();

    List<List<StringDynamicMap>> serializedRelics = playerRelics.map((
      playerList,
    ) {
      return playerList.map((relic) => relic.toJson()).toList();
    }).toList();

    return {
      _BoardKeys.myPlayerIndex: targetPlayerIndex,
      _BoardKeys.currentPlayer: currentPlayer,
      _BoardKeys.direction: isClockwise,
      _BoardKeys.topCard: topCardJson,
      _BoardKeys.deckSize: deck.length,
      _BoardKeys.myHand: myHandJson,
      _BoardKeys.opponentHandSizes: handSizes,
      _BoardKeys.pendingDrawCount: pendingDrawCount,
      _BoardKeys.declaredColor: declaredColor?.index,
      _BoardKeys.actionPoints: actionPoints,
      _BoardKeys.cardDraws: cardDraws,
      _BoardKeys.hasPlayedCard: hasPlayedCard,
      _BoardKeys.hasDrawnCard: hasDrawnCard,
      _BoardKeys.playerRelics: serializedRelics,
      _BoardKeys.winnerIndex: winnerIndex,
      _BoardKeys.turnDeadline: turnDeadlineEpoch,
      _BoardKeys.roundCount: roundCount,
      _BoardKeys.activeDeckEvent: activeDeckEvent.index,
    };
  }

  /// CLIENT ONLY: Takes the JSON from the Host and forces the local UI to match it.
  List<IshiCard> applyGameStateJson(StringDynamicMap json) {
    localPlayerIndex = json[_BoardKeys.myPlayerIndex] as int;
    currentPlayer = json[_BoardKeys.currentPlayer] as int;
    isClockwise = json[_BoardKeys.direction] as bool;
    pendingDrawCount = json[_BoardKeys.pendingDrawCount] as int;

    if (json[_BoardKeys.declaredColor] != null) {
      declaredColor = CardColor.values[json[_BoardKeys.declaredColor] as int];
    } else {
      declaredColor = null;
    }

    if (opponentHandSizes.isEmpty) {
      opponentHandSizes = List<int>.from(json[_BoardKeys.opponentHandSizes]);
      playerHands = List.generate(opponentHandSizes.length, (_) => []);
      playerRelics = List.generate(opponentHandSizes.length, (_) => []);
    } else {
      opponentHandSizes = List<int>.from(json[_BoardKeys.opponentHandSizes]);
    }

    actionPoints = List<int>.from(
      json[_BoardKeys.actionPoints] ?? List.filled(opponentHandSizes.length, 0),
    );
    cardDraws = List<int>.from(
      json[_BoardKeys.cardDraws] ?? List.filled(opponentHandSizes.length, 0),
    );

    if (json[_BoardKeys.topCard] != null) {
      discardPile = [IshiCard.fromJson(json[_BoardKeys.topCard])];
    }

    List<IshiCard> newlyDealtCards = [];

    if (json[_BoardKeys.myHand] != null) {
      final List<dynamic> handData = json[_BoardKeys.myHand];
      List<IshiCard> incomingHand = handData
          .map((c) => IshiCard.fromJson(c as StringDynamicMap))
          .toList();

      // Preserve LOCAL sorted order for existing cards
      List<IshiCard> preservedLocalHand = [];
      for (IshiCard localCard in playerHands[localPlayerIndex]) {
        if (incomingHand.any((c) => c.id == localCard.id)) {
          preservedLocalHand.add(localCard);
        }
      }

      // Find the brand new cards the Host gave us
      for (IshiCard incomingCard in incomingHand) {
        if (!preservedLocalHand.any((c) => c.id == incomingCard.id)) {
          newlyDealtCards.add(
            incomingCard,
          ); // Intercept! Do not add to hand yet.
        }
      }

      // Update the local hand with ONLY the preserved cards (maintaining their sort)
      playerHands[localPlayerIndex] = preservedLocalHand;
    }

    if (json[_BoardKeys.playerRelics] != null) {
      List<dynamic> incomingRelics = json[_BoardKeys.playerRelics];
      for (int i = 0; i < incomingRelics.length; i++) {
        List<dynamic> relicData = incomingRelics[i];

        playerRelics[i] = relicData
            .map((r) => Relic.fromJson(r as StringDynamicMap))
            .toList();
      }
    }

    int incomingDeckSize = json[_BoardKeys.deckSize] as int? ?? 0;
    if (deck.length != incomingDeckSize) {
      deck.clear();
      deck.addAll(
        List.generate(
          incomingDeckSize,
          (i) => IshiCard(id: 'dummy_$i', color: .wild, type: .number),
        ),
      );
    }

    hasPlayedCard = json[_BoardKeys.hasPlayedCard] as bool? ?? false;
    hasDrawnCard = json[_BoardKeys.hasDrawnCard] as bool? ?? false;
    turnDeadlineEpoch = json[_BoardKeys.turnDeadline] as int? ?? 0;
    roundCount = json[_BoardKeys.roundCount] as int? ?? 1;
    activeDeckEvent =
        DeckEventEffect.values[json[_BoardKeys.activeDeckEvent] as int? ??
            DeckEventEffect.none.index];

    int? incomingWinner = json[_BoardKeys.winnerIndex] as int?;
    if (winnerIndex == null && incomingWinner != null) {
      winnerIndex = incomingWinner;
      addEvent(.gameOver);
    } else {
      winnerIndex = incomingWinner;
    }

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

    if (playerAP <= 0 && playerCD <= 0) {
      return false;
    }

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
  CanPlayRecord canPlay(IshiCard card, int playerIndex) {
    final CanPlayRecord canPlayNoReason = (canPlay: true, reason: null);
    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && card.color == .wild) {
      apCost = 2;
    }
    if (actionPoints[playerIndex] < apCost) {
      return (canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (pendingDrawCount > 0) {
      if (card.type == topCard.type) return canPlayNoReason;

      // DEFLECTION MECHANICS
      bool isNaturalSkip = card.type == .skip;
      bool isBlueFreezeSkip =
          activeDeckEvent == .blueCardsFreeze && card.color == .blue;

      if ((isNaturalSkip || isBlueFreezeSkip) &&
          (topCard.color == .wild || card.color == topCard.color)) {
        return canPlayNoReason;
      }
      return (canPlay: false, reason: "Card cannot deflect incoming attack!");
    }

    if (actionPoints[playerIndex] <= 0) {
      return (canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (card.color == .wild) return canPlayNoReason;
    if (declaredColor != null) {
      final isSameColor = card.color == declaredColor;
      return (
        canPlay: isSameColor,
        reason: isSameColor ? null : "Card color doesn't match!",
      );
    }

    if (topCard.color == .wild) return canPlayNoReason;
    if (card.color == topCard.color) return canPlayNoReason;
    if (card.type == topCard.type) {
      if (card.type == .number) {
        final isSameNumber = card.number == topCard.number;
        return (
          canPlay: isSameNumber,
          reason: isSameNumber ? null : "Card number doesn't match!",
        );
      }
      return canPlayNoReason; // Skips, Reverses, etc. match type
    }
    return (canPlay: false, reason: "Invalid card!");
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
        }
        break;
      case .skip:
        if (pendingDrawCount > 0) {
          //? DEFENSIVE SKIP: The player successfully deflected!
          // We DO NOT increment _playersToSkip, because we want the VERY NEXT player
          // to face the pendingDrawCount bomb. The stack size stays exactly the same.
        } else {
          //? OFFENSIVE SKIP: Normal play, the next player loses their turn.
          _playersToSkip++;
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
