import 'dart:async';

import 'package:ishi/core/data_types.dart';
import 'package:ishi/models/relic.dart';
import 'package:ishi/models/ishi_card.dart';

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
}

enum GameManagerEvent { gameOver }

class GameManager {
  // --- CORE STATES ---
  List<IshiCard> deck = [];
  List<IshiCard> discardPile = [];

  /// `playerHands`[`playerIndex`][`cardIndex`]
  late List<List<IshiCard>> playerHands;

  int playerCount;

  // --- ECONOMY STATES ---
  late List<int> actionPoints;
  late List<int> cardDraws;
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

  GameManager({required this.playerCount, required this.startingHandSize});

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
    deck = generateStandardDeck();
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
        if (canPlay(card, playerIndex)) return true;
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
  bool canPlay(IshiCard card, int playerIndex) {
    if (actionPoints[playerIndex] <= 0) return false;

    if (pendingDrawCount > 0) {
      if (card.type == topCard.type) return true;

      // You can DEFLECT with a Skip card,
      // but it must match the color of the attack
      // (If the top card is a Wild +4, we allow any color Skip to counter it)
      if (card.type == .skip &&
          (topCard.color == .wild || card.color == topCard.color)) {
        return true;
      }
      return false; // Nothing else is allowed while under attack
    }

    if (card.color == .wild) return true;
    if (declaredColor != null) return card.color == declaredColor;

    if (topCard.color == .wild) return true;
    if (card.color == topCard.color) return true;
    if (card.type == topCard.type) {
      if (card.type == .number) return card.number == topCard.number;
      return true; // Skips, Reverses, etc. match type
    }
    return false;
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
    actionPoints[playerIndex]--;

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
    if (!skipHandInsertion) {
      playerHands[playerIndex].insert(0, drawn);
    }

    hasDrawnCard = true;

    // Only auto-sort instantly if we inserted the card instantly
    if (!skipHandInsertion && playerIndex == localPlayerIndex) {
      sortHand(playerIndex, handSortType);
    }

    return drawn;
  }

  // THE UNO RULES ENGINE
  void _applyCardEffect(IshiCard card) {
    switch (card.type) {
      case .reverse:
        if (playerCount == 2) {
          _playersToSkip++;
        } else {
          isClockwise = !isClockwise;
        }
        break;
      case .skip:
        if (pendingDrawCount > 0) {
          // DEFENSIVE SKIP: The player successfully deflected!
          // We DO NOT increment _playersToSkip, because we want the VERY NEXT player
          // to face the pendingDrawCount bomb. The stack size stays exactly the same.
        } else {
          // OFFENSIVE SKIP: Normal play, the next player loses their turn.
          _playersToSkip++;
        }
        break;
      case .draw2:
        pendingDrawCount += 2;
        break;
      case .wildDraw4:
        pendingDrawCount += 4;
        break;
      default:
        break;
    }
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

    if (currentPlayer == 1) roundCount++;

    int playerIndex = currentPlayer - 1;

    // Calculate base economies + relic bonuses
    int bonusAP = playerRelics[playerIndex]
        .where((r) => r.effect == .addActionPoint)
        .length;
    int bonusCD = playerRelics[playerIndex]
        .where((r) => r.effect == .addCardDraw)
        .length;

    actionPoints[currentPlayer - 1] = 1 + bonusAP;
    cardDraws[currentPlayer - 1] = 1 + bonusCD;
    hasPlayedCard = false;
    hasDrawnCard = false;
    hasDeflected = false;
    turnDeadlineEpoch = _getTurnDeadlineEpoch;
  }
}
