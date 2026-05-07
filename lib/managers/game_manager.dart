import 'package:esther_gift/models/relic.dart';
import 'package:esther_gift/models/uno_card.dart';

class GameManager {
  final int playerCount;

  // --- CORE STATES ---
  List<UnoCard> deck = [];
  List<UnoCard> discardPile = [];

  /// `playerHands`[`playerIndex`][`cardIndex`]
  late List<List<UnoCard>> playerHands;

  // --- ECONOMY STATES ---
  late List<int> actionPoints;
  late List<int> cardDraws;
  late List<List<Relic>> playerRelics;

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

  GameManager({required this.playerCount, required int startingHandSize}) {
    _initializeGame(startingHandSize);
  }

  int getCardIndexByPlayerIndex(UnoCard card) =>
      playerHands[currentPlayer - 1].indexOf(card);

  UnoCard? getCardOfCurrentPlayer(UnoCard card) {
    final int playerIndex = currentPlayer - 1;
    final int cardIndex = getCardIndexByPlayerIndex(card);
    if (cardIndex == -1) return null;
    return playerHands[playerIndex][cardIndex];
  }

  void _initializeGame(int startingHandSize) {
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
