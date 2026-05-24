part of 'game_screen.dart';

extension GameEvents on GameScreenState {
  void _onChaosTrigger() =>
      _newMessages.add(const CombatMessage(text: "CHAOS!", color: Colors.red));

  void _onWildBuffTrigger() => _newMessages.add(
    const CombatMessage(
      text: "DOUBLE TROUBLE!",
      color: Colors.deepPurpleAccent,
    ),
  );

  void _onEvolvedTrigger() => _newMessages.add(
    CombatMessage(
      text: "EVOLVED! (${_manager.pendingEvolutions} left)",
      color: Colors.lightGreenAccent,
    ),
  );

  void _onFrozenTrigger() => _newMessages.add(
    const CombatMessage(text: "FROZEN!", color: Colors.lightBlueAccent),
  );

  void triggerCombatMessages(IshiCard playedCard) {
    final event = _manager.activeDeckEvent;

    // DECK MODIFYING EVENTS
    if (event == .greenCardsEvolution && playedCard.color == .green) {
      _newMessages.add(
        CombatMessage(
          text: "EVOLUTION +${_manager.pendingEvolutions}!",
          color: Colors.lightGreen,
          fontSize: 32,
        ),
      );
    }

    if (event == .yellowCardsUnflux && playedCard.color == .yellow) {
      _newMessages.add(
        const CombatMessage(text: "UNFLUX!", color: Colors.amberAccent),
      );
    }

    // STANDARD RULES
    if (playedCard.type == .reverse) {
      _newMessages.add(
        const CombatMessage(text: "REVERSED!", color: Colors.amber),
      );
    } else if (playedCard.type == .skip) {
      _newMessages.add(
        const CombatMessage(text: "SKIPPED!", color: Colors.blueAccent),
      );
    }

    // STACKING PENALTIES
    if (playedCard.type == .draw2 || playedCard.type == .draw4) {
      _newMessages.add(
        CombatMessage(
          text: "STACK +${_manager.pendingDrawCount}!",
          color: Colors.redAccent,
          fontSize: 56,
        ),
      );
    }

    if (_newMessages.isEmpty) return;
    updateUI(() {
      _currentCombatMessages = List.from(_newMessages);
      _combatMessagesKey = UniqueKey();
    });
    _newMessages.clear();
  }
}
