part of 'game_screen.dart';

extension GameComponents on GameScreenState {
  Widget _buildRelicDisplay() => RelicDisplay(
    relics: _manager.playerRelics[_manager.localPlayerIndex],
    onTapRelic: (isActiveRelic, relic) {
      if (!isMyTurn || !isActiveRelic) return;
      updateUI(() {
        if (_activeTargetingRelic == relic) {
          _activeTargetingRelic = null;
          _relicTargets.clear();
        } else {
          _activeTargetingRelic = relic;
          _relicTargets.clear();
          _isViewingRelics = false;
        }
      });
    },
  );

  /// THE PLAY PILE (Center)
  Stack _playPileAndDeck() => Stack(
    alignment: .center,
    clipBehavior: .none,
    children: [
      PlayAndPileDeck(
        manager: _manager,
        onDrawCard: drawCardAction,
        onPlayCard: playCardAction,
        playPileKey: playPileKey,
      ),
      if (_currentCombatMessages.isNotEmpty)
        Positioned(
          top: -20,
          child: FloatingCombatTextGroup(
            key: _combatMessagesKey,
            interval: const Duration(milliseconds: 500),
            messages: _currentCombatMessages,
          ),
        ),
    ],
  );

  /// LOCAL PLAYER DASHBOARD (Bottom)
  Column _lowerPanel() {
    final animatedCardList = AnimatedCardList(
      animatedListKey: listKeys[localUIIndex],
      currentHand: currentHand,
      selectedCards: _activeTargetingRelic != null
          ? _relicTargets
          : (_selectedCard != null ? [_selectedCard!] : []),
      onTapCard: (card) {
        if (!isMyTurn) return;

        updateUI(() {
          if (_activeTargetingRelic != null) {
            if (_relicTargets.contains(card)) {
              _relicTargets.remove(card); // Deselect target
            } else {
              // Select target/s
              int maxTargets = _activeTargetingRelic!.effect == .obliterate
                  ? 5
                  : 1;
              if (_relicTargets.length < maxTargets) {
                _relicTargets.add(card);
              }
            }
            return;
          }

          _selectedCard = _selectedCard == card ? null : card;
        });
      },
      scrollController: scrollControllers[localUIIndex],
      isMyTurn: isMyTurn,
      event: _manager.activeDeckEvent,
    );

    final cardViewSwapButton = ElevatedButton.icon(
      onPressed: () => updateUI(() => _isViewingRelics = !_isViewingRelics),
      label: Text(_isViewingRelics ? "VIEW CARDS" : "VIEW RELICS"),
      icon: Icon(_isViewingRelics ? Icons.style : Icons.auto_awesome),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isViewingRelics
            ? Colors.grey.shade800
            : Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
    );

    final cardsDisplay = RawScrollbar(
      key: ValueKey(scrollControllers[localUIIndex]),
      controller: scrollControllers[localUIIndex],
      thumbVisibility: true,
      thumbColor: Colors.black26,
      radius: const .circular(8),
      thickness: 6,
      child: animatedCardList,
    );

    final playerRelics = _manager.playerRelics[_manager.localPlayerIndex];

    Widget? targetingBanner;
    if (_activeTargetingRelic != null) {
      targetingBanner = _targetingBanner().animate().fadeIn().slideY(
        begin: 0.5,
      );
    }

    return Column(
      mainAxisSize: .min,
      children: [
        Row(
          mainAxisAlignment: .center,
          children: [
            CardCounter(currentHandLength: currentHand.length),
            if (playerRelics.isNotEmpty) ...[
              const SizedBox(width: 16),
              cardViewSwapButton.animate().fadeIn().slideX(),
            ],
          ],
        ),
        if (_activeTargetingRelic != null) ...[
          const SizedBox(height: 16),
          targetingBanner!,
        ],
        if (_activeTargetingRelic == null && !_isViewingRelics) ...[
          Opacity(
            opacity: isMyTurn ? 1.0 : 0.5,
            child: HandControls(
              onEndTurn: endTurnAction,
              onFlipAllCard: flipAllCardsAction,
              onSortHand: animatedSort,
              onTakePenalty: takePenaltyAction,
              onToggleAutoSort: () => updateUI(
                () => _manager.isAutoSortEnabled = !_manager.isAutoSortEnabled,
              ),
              manager: _manager,
              isMyTurn: isMyTurn,
            ),
          ),
          AnimatedPlayButton(
            selectedCard: _selectedCard,
            isMyTurn: isMyTurn,
            onPlay: () async => playCardAction(_selectedCard!),
          ),
        ],
        Container(
          height: 280,
          padding: const .symmetric(horizontal: 8, vertical: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isViewingRelics
                ? SizedBox(
                    key: const ValueKey('relics_view'),
                    child: _buildRelicDisplay(),
                  )
                : cardsDisplay,
          ),
        ),
        SizedBox(height: _isViewingRelics ? 32 : 16),
      ],
    );
  }

  Container _targetingBanner() {
    int maxTargets = _activeTargetingRelic!.effect == .obliterate ? 5 : 1;

    final usingRelicIndicator = Row(
      mainAxisSize: .min,
      children: [
        Text(
          "USING: ${_activeTargetingRelic!.name.toUpperCase()}",
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => updateUI(() {
            _activeTargetingRelic = null;
            _relicTargets.clear();
          }),
        ),
      ],
    );

    final targetsLeftIndicator = Row(
      mainAxisSize: .min,
      children: [
        const Icon(Icons.track_changes, color: Colors.white),
        const SizedBox(width: 12),
        Text(
          "TARGETING: ${_relicTargets.length}/$maxTargets",
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        if (_relicTargets.isNotEmpty) ...[
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _executeActiveRelic(),
            child: const Text(
              "CONFIRM",
              style: TextStyle(color: Colors.white, fontWeight: .bold),
            ),
          ),
        ],
      ],
    );

    return Container(
      margin: const .only(bottom: 16),
      padding: const .symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        border: .all(color: Colors.redAccent, width: 2),
        borderRadius: .circular(12),
      ),
      child: Column(children: [usingRelicIndicator, targetsLeftIndicator]),
    );
  }

  IconButton _settingsButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.settings, color: Colors.white),
    tooltip: "Show Settings",
    onPressed: () => showDialog(
      context: context,
      builder: (_) => GameSettingsDialog(
        onExitGame: _promptLeaveGame,
        onDevConsoleToggle: () {
          Navigator.pop(context);
          updateUI(() => _showDevConsole = !_showDevConsole);
        },
        showDevConsoleToggle: _showDevConsoleToggle,
      ),
    ),
  );

  PingToggleButton get _pingToggleButton => PingToggleButton(
    showPingOverlay: _showPingOverlay,
    onToggle: () => updateUI(() => _showPingOverlay = !_showPingOverlay),
    onLongPress: () => showDialog(
      context: context,
      builder: (_) => DevConsoleToggleDialog(
        showDevConsole: _showDevConsoleToggle,
        onToggle: (val) => updateUI(() => _showDevConsoleToggle = val),
      ),
    ),
  );

  Container get _roundIndicator => Container(
    padding: const .symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: .circular(16),
      border: .all(color: Colors.white24, width: 1),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        "ROUND ${_manager.roundCount}",
        key: ValueKey<int>(_manager.roundCount),
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: .bold,
          letterSpacing: 2,
          fontSize: 16,
        ),
      ),
    ),
  );
}
