part of 'game_manager.dart';

extension GameEvents on GameManager {
  /// Helper to completely scramble a card (Butterfly Effect).
  IshiCard _randomizeNewCard(IshiCard originalCard) {
    final colors = CardColor.getNormalColors;
    final random = Random();

    final newType = CardType.values[random.nextInt(CardType.values.length)];

    final isWildType = CardType.getWildTypes.contains(newType);

    final CardColor newColor = isWildType
        ? .wild
        : colors[random.nextInt(colors.length)];

    int? newNumber;
    // Generates 0 -> 9
    if (newType == .number) newNumber = random.nextInt(10);

    final newCard = IshiCard(
      id: originalCard.id,
      isFaceUp: originalCard.isFaceUp,
      color: newColor,
      type: newType,
      number: newNumber,
    );

    debugPrint(
      "<-------------------(_randomizeNewCard)------------------->\n"
      "Generating new random card...\n"
      "Before: ${originalCard.toString()}\n"
      "After: ${newCard.toString()}\n"
      "<--------------------------------------------------------->\n",
    );
    return newCard;
  }

  /// Helper to Evolve a card (Green Evolution).
  IshiCard _evolveCard(IshiCard card) {
    if (card.type == .draw2) {
      debugPrint(
        "(_evolveCard) Evolving draw2 (${card.color.name}) -> draw4 (wild)",
      );
      return card.clone(newColor: .wild, newType: .draw4);
    }

    final isCardNumberType = card.type == .number && card.number != null;

    if ((isCardNumberType && card.number == 9) || card.type == .skip) {
      final colors = CardColor.getNormalColors;
      int nextColorIndex = (colors.indexOf(card.color) + 1) % colors.length;
      debugPrint(
        "(_evolveCard) Changing color from: ${card.color.name} -> "
        "${colors[nextColorIndex].name}",
      );
      return card.clone(newColor: colors[nextColorIndex]);
    }

    if (isCardNumberType && card.number! >= 0 && card.number! < 9) {
      debugPrint(
        "(_evolveCard) Incrementing value from: ${card.number} -> "
        "${card.number! + 1}",
      );
      return card.clone(newNumber: card.number! + 1);
    }

    debugPrint("(_evolveCard) No evolution has been done.");
    return card; // Fallback if it can't evolve
  }

  /// Handles other event-driven card effects.
  IshiCard _onPlayCardEventEffect(IshiCard playedCard) {
    // BUTTERFLY EFFECT
    if (activeDeckEvent == .butterflyEffect) {
      if (Random().nextDouble() < chaosEffectChance) {
        playedCard = _randomizeNewCard(playedCard);
        if (onChaosTrigger != null) onChaosTrigger!();
      }
    }
    // GREEN EVOLUTION
    else if (activeDeckEvent == .greenCardsEvolution) {
      if (pendingEvolutions > 0 && playedCard.color == .green) {
        pendingEvolutions++;
        debugPrint(
          "(_onPlayCardEventEffect) Evolving card: ${playedCard.id}, "
          "pendingEvolutions: $pendingEvolutions",
        );
        playedCard = _evolveCard(playedCard);
        if (onEvolvedTrigger != null) onEvolvedTrigger!();
      } else if (playedCard.color == .green) {
        pendingEvolutions++;
        debugPrint(
          "(_onPlayCardEventEffect) pendingEvolutions: $pendingEvolutions",
        );
      } else if (pendingEvolutions > 0) {
        debugPrint("(_onPlayCardEventEffect) Evolving card: ${playedCard.id}");
        playedCard = _evolveCard(playedCard);
        pendingEvolutions--;
        debugPrint(
          "(_onPlayCardEventEffect) pendingEvolutions: $pendingEvolutions",
        );
        if (onEvolvedTrigger != null) onEvolvedTrigger!();
      }
    }

    return playedCard;
  }

  void _applyActiveDeckEventEffects(IshiCard playedCard) {
    // RED BURN
    if (activeDeckEvent == .redCardsBurn && playedCard.color == .red) {
      pendingDrawCount += 1;
    }

    // BLUE FREEZE
    if (playedCard.type != .skip &&
        pendingDrawCount == 0 &&
        activeDeckEvent == .blueCardsFreeze &&
        playedCard.color == .blue) {
      _playersToSkip++; // Add offensive skip
      if (onFrozenTrigger != null) onFrozenTrigger!();
    }

    // YELLOW REVERSE
    if (activeDeckEvent == .yellowCardsUnflux &&
        playedCard.type != .reverse &&
        pendingDrawCount == 0 &&
        playedCard.color == .yellow) {
      if (playerCount == 2) {
        _playersToSkip++; // In 1v1, it acts as a Skip
      } else {
        isClockwise = !isClockwise; // In 3+ players, it acts as a Reverse
      }
    }

    // WILDS DOUBLE EFFECT
    if (activeDeckEvent == .wildDoubleTrouble &&
        playedCard.color == .wild &&
        playedCard.type == .draw4) {
      pendingDrawCount += 4;
      if (onWildBuffTrigger != null) onWildBuffTrigger!();
    }
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
}
