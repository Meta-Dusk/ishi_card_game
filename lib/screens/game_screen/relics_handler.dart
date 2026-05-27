part of 'game_screen.dart';

extension RelicsHandler on GameScreenState {
  Future<void> _executeActiveRelic() async {
    final relic = _activeTargetingRelic!;
    final targets = List<IshiCard>.from(_relicTargets);
    final playerIndex = _manager.localPlayerIndex;

    IshiCard? chosenTemplate;

    // RELIC USAGE DIALOGS
    debugPrint(
      "<-----------(_executeActiveRelic)----------->\n"
      "Using relic: ${relic.toString()}\n"
      "has onUseDialog: ${relic.onUseDialog == null ? "false" : "true"}\n"
      "<------------------------------------------->\n",
    );
    if (relic.onUseDialog != null) {
      chosenTemplate = await relic.onUseDialog!(
        context: context,
        manager: _manager,
        relic: relic,
      );
      if (chosenTemplate == null) return; // Game cancels the usage
    }

    updateUI(() {
      if (relic.useCost != null) {
        _manager.actionPoints[_manager.localPlayerIndex] -= relic.useCost!;
      }
      if (chosenTemplate != null) {
        relic.memory.add(chosenTemplate.id);
      }
      _activeTargetingRelic = null;
      _relicTargets.clear();
      _isViewingRelics = false;
    });

    await _applyRelicEffectLocally(
      playerIndex: playerIndex,
      relic: relic,
      targets: targets,
      chosenTemplate: chosenTemplate,
    );

    if (_net.isHost) {
      broadcastGameState();
      _evaluateSmartAutoEnd();
    } else {
      _net.sendIntent(
        PlayIntentMessage(
          action: .activateRelic,
          playerIndex: playerIndex,
          relicId: relic.id,
          targetCardIds: targets.map((c) => c.id).toList(),
          polymorphTemplate: chosenTemplate?.toJson(),
        ),
      );
      _evaluateSmartAutoEnd();
    }
  }

  /// Process the targets and trigger UI animations.
  Future<void> _applyRelicEffectLocally({
    required int playerIndex,
    required Relic relic,
    required List<IshiCard> targets,
    IshiCard? chosenTemplate,
  }) async {
    updateUI(() {
      switch (relic.effect) {
        case .polymorph:
          if (chosenTemplate == null) break;
          relic.onUse!(
            card: chosenTemplate,
            manager: _manager,
            gameState: this,
            targets: targets,
            playerIndex: playerIndex,
          );
          break;

        default:
          if (relic.onUse == null) break;
          relic.onUse!(
            gameState: this,
            manager: _manager,
            relic: relic,
            targets: targets,
            playerIndex: playerIndex,
          );
          break;
      }

      // CONSUMPTION: Remove single-use relics or decrease durability!
      try {
        final inventoryRelic = _manager.playerRelics[playerIndex].firstWhere(
          (r) => r.id == relic.id,
        );

        if (inventoryRelic.maxUses != null) {
          inventoryRelic.usesLeft =
              (inventoryRelic.usesLeft ?? inventoryRelic.maxUses!) - 1;

          if (inventoryRelic.usesLeft! <= 0) {
            _manager.playerRelics[playerIndex].remove(inventoryRelic);
          }
        } else if (inventoryRelic.types.contains(RelicEffectType.singleUse)) {
          _manager.playerRelics[playerIndex].remove(inventoryRelic);
        }
      } catch (e) {
        debugPrint("Relic is already consumed or: $e");
      }
    });

    Future.delayed(
      const Duration(milliseconds: 400),
      () => flipAllCardsAction(onlyFlipIfFaceDown: true),
    );
  }
}
