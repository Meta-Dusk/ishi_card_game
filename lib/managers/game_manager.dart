import 'package:esther_gift/core/data_types.dart';
import 'package:esther_gift/models/relic.dart';
import 'package:esther_gift/models/uno_card.dart';
import '../core/network_keys.dart';

class GameManager {
  int playerCount;

  // --- CORE STATES ---
  List<UnoCard> deck = [];
  List<UnoCard> discardPile = [];

  /// `playerHands`[`playerIndex`][`cardIndex`]
  late List<List<UnoCard>> playerHands;

  // --- ECONOMY STATES ---
  late List<int> actionPoints;
  late List<int> cardDraws;
  late List<List<Relic>> playerRelics;
  final int startingHandSize;

  // --- TURN STATES ---
  int currentPlayer = 1;
  int pendingDrawCount = 0;
  CardColor? declaredColor;

  /// The turn direction.
  bool isClockwise = true;

  /// Stacks if multiple skips are played.
  int _playersToSkip = 0;

  // --- ACTION STATES ---
  bool hasPlayedCard = false;
  bool hasDrawnCard = false;
  bool hasDeflected = false;

  // LAN STATES

  /// The Host is always 0. Clients will update this!
  int localPlayerIndex = 0;

  /// Stores the card counts for the UI.
  List<int> opponentHandSizes = [];

  GameManager({required this.playerCount, required this.startingHandSize});

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

    List<List<String>> serializedRelics = playerRelics.map((playerList) {
      return playerList.map((relic) => relic.id).toList();
    }).toList();

    return {
      NetKey.type: NetKey.gameStateUpdate,
      NetKey.myPlayerIndex: targetPlayerIndex,
      NetKey.currentPlayer: currentPlayer,
      NetKey.direction: isClockwise,
      NetKey.topCard: topCardJson,
      NetKey.deckSize: deck.length,
      NetKey.myHand: myHandJson,
      NetKey.opponentHandSizes: handSizes,
      NetKey.pendingDrawCount: pendingDrawCount,
      NetKey.declaredColor: declaredColor?.index,
      NetKey.actionPoints: actionPoints,
      NetKey.cardDraws: cardDraws,
      NetKey.hasPlayedCard: hasPlayedCard,
      NetKey.hasDrawnCard: hasDrawnCard,
      NetKey.playerRelics: serializedRelics,
    };
  }

  /// CLIENT ONLY: Takes the JSON from the Host and forces the local UI to match it.
  void applyGameStateJson(StringDynamicMap json) {
    localPlayerIndex = json[NetKey.myPlayerIndex] as int;
    currentPlayer = json[NetKey.currentPlayer] as int;
    isClockwise = json[NetKey.direction] as bool;
    pendingDrawCount = json[NetKey.pendingDrawCount] as int;

    if (json[NetKey.declaredColor] != null) {
      declaredColor = CardColor.values[json[NetKey.declaredColor] as int];
    } else {
      declaredColor = null;
    }

    if (opponentHandSizes.isEmpty) {
      opponentHandSizes = List<int>.from(json[NetKey.opponentHandSizes]);
      playerHands = List.generate(opponentHandSizes.length, (_) => []);
      playerRelics = List.generate(opponentHandSizes.length, (_) => []);
    } else {
      opponentHandSizes = List<int>.from(json[NetKey.opponentHandSizes]);
    }

    actionPoints = List<int>.from(
      json[NetKey.actionPoints] ?? List.filled(opponentHandSizes.length, 0),
    );
    cardDraws = List<int>.from(
      json[NetKey.cardDraws] ?? List.filled(opponentHandSizes.length, 0),
    );

    if (json[NetKey.topCard] != null) {
      discardPile = [UnoCard.fromJson(json[NetKey.topCard])];
    }

    if (json[NetKey.myHand] != null) {
      final List<dynamic> handData = json[NetKey.myHand];
      List<UnoCard> incomingHand = handData
          .map((c) => UnoCard.fromJson(c))
          .toList();

      List<UnoCard> mergedHand = [];
      for (var newCard in incomingHand) {
        // Check if we already hold this exact card ID in our local hand
        int existingIdx = playerHands[localPlayerIndex].indexWhere(
          (card) => card.id == newCard.id,
        );

        if (existingIdx != -1) {
          // If we do, keep the exact local object! This perfectly preserves
          // the face-up status and any ongoing animations.
          mergedHand.add(playerHands[localPlayerIndex][existingIdx]);
        } else {
          // If we don't, it's a freshly drawn card. Add the new one!
          mergedHand.add(newCard);
        }
      }
      playerHands[localPlayerIndex] = mergedHand;
    }

    if (json[NetKey.playerRelics] != null) {
      List<dynamic> incomingRelics = json[NetKey.playerRelics];
      for (int i = 0; i < incomingRelics.length; i++) {
        List<dynamic> relicIds = incomingRelics[i];

        // Convert the string IDs back into actual Relic objects using the pool
        playerRelics[i] = relicIds
            .map((id) => relicPool.firstWhere((r) => r.id == id))
            .toList();
      }
    }

    int incomingDeckSize = json[NetKey.deckSize] as int? ?? 0;
    if (deck.length != incomingDeckSize) {
      deck.clear();
      deck.addAll(
        List.generate(
          incomingDeckSize,
          (i) => UnoCard(id: 'dummy_$i', color: .wild, type: .number),
        ),
      );
    }

    if (json[NetKey.myHand] != null) {
      final List<dynamic> handData = json[NetKey.myHand];
      List<UnoCard> incomingHand = handData
          .map((c) => UnoCard.fromJson(c))
          .toList();

      for (var newCard in incomingHand) {
        // Look to see if we already hold this card locally
        final existingCard = playerHands[localPlayerIndex]
            .cast<UnoCard?>()
            .firstWhere((c) => c?.id == newCard.id, orElse: () => null);

        // If we do, copy our local face-up state to the new incoming card!
        if (existingCard != null) {
          newCard.isFaceUp = existingCard.isFaceUp;
        }
      }
      playerHands[localPlayerIndex] = incomingHand;
    }

    hasPlayedCard = json[NetKey.hasPlayedCard] as bool? ?? false;
    hasDrawnCard = json[NetKey.hasDrawnCard] as bool? ?? false;
  }

  int getCardIndexByPlayerIndex(UnoCard card) =>
      playerHands[currentPlayer - 1].indexOf(card);

  UnoCard? getCardOfCurrentPlayer(UnoCard card) {
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
  }

  void sortHand(int playerIndex, {required bool byColor}) {
    playerHands[playerIndex].sort((a, b) {
      if (byColor) {
        // Sort by Color -> Type -> Number
        int colorComp = a.color.index.compareTo(b.color.index);
        if (colorComp != 0) return colorComp;

        int typeComp = a.type.index.compareTo(b.type.index);
        if (typeComp != 0) return typeComp;

        return (a.number ?? -1).compareTo(b.number ?? -1);
      } else {
        // Sort by Type -> Number -> Color
        int typeComp = a.type.index.compareTo(b.type.index);
        if (typeComp != 0) return typeComp;

        int numComp = (a.number ?? -1).compareTo(b.number ?? -1);
        if (numComp != 0) return numComp;

        return a.color.index.compareTo(b.color.index);
      }
    });
  }

  /// Gets the current active card on the play pile.
  UnoCard get topCard => discardPile.last;

  /// RULE EVALUATION: Can this card be played?
  bool canPlay(UnoCard card, int playerIndex) {
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

  void resolvePendingAttack() {
    int playerIndex = currentPlayer - 1;
    for (int i = 0; i < pendingDrawCount; i++) {
      if (deck.isNotEmpty) {
        playerHands[playerIndex].insert(0, deck.removeLast());
      }
    }
    pendingDrawCount = 0;
    actionPoints[playerIndex] = 0; // Force their turn to end
    cardDraws[playerIndex] = 0; // Prevent them from digging for answers
    hasDrawnCard = true;
  }

  /// ACTION: Play a card and apply its effects
  void playCard(int playerIndex, int cardIndex) {
    bool wasUnderAttack = pendingDrawCount > 0;
    UnoCard playedCard = playerHands[playerIndex].removeAt(cardIndex);
    actionPoints[playerIndex]--;

    playedCard.isFaceUp = true;
    discardPile.add(playedCard);
    _applyCardEffect(playedCard);

    hasPlayedCard = true;
    declaredColor = null;
    if (wasUnderAttack) hasDeflected = true;
  }

  void setDeclaredColor(CardColor color) => declaredColor = color;

  /// ACTION: Draw a card
  UnoCard drawCard(int playerIndex) {
    cardDraws[playerIndex]--;
    UnoCard drawn = deck.removeLast();
    playerHands[playerIndex].insert(0, drawn);
    hasDrawnCard = true;
    return drawn;
  }

  // THE UNO RULES ENGINE
  void _applyCardEffect(UnoCard card) {
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
  void forceDraw(int targetPlayerIndex, int count) {
    for (int i = 0; i < count; i++) {
      if (deck.isNotEmpty) {
        UnoCard drawn = deck.removeLast();
        playerHands[targetPlayerIndex].insert(0, drawn);
      }
    }
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
  }
}
