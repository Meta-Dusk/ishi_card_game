part of 'game_manager.dart';

extension GameRules on GameManager {
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
}
