import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/gameplay/relic_display.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/services/network_service.dart';
import 'imports/game_components.dart';
import 'imports/game_core.dart';

part 'actions.dart';
part 'network.dart';

class GameScreen extends StatefulWidget {
  final GameManager manager;
  final NetworkService network;

  const GameScreen({super.key, required this.manager, required this.network});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late GameManager _manager;

  NetworkService get _net => widget.network;
  late StreamSubscription? _netSubscription;
  late StreamSubscription? _gameEventSubscription;

  String? attackMessage;
  Key attackKey = UniqueKey();

  late Map<int, GlobalKey<AnimatedListState>> listKeys;
  late Map<int, ScrollController> scrollControllers;

  bool _showPingOverlay = false;
  late StreamSubscription? _pingSubscription;
  final playPileKey = GlobalKey<PlayCardsPileState>();

  int get localUIIndex => _manager.localPlayerIndex + 1;
  AnimatedListState? get getCurrentState =>
      listKeys[localUIIndex]?.currentState;
  bool get isMyTurn => _manager.currentPlayer == localUIIndex;
  List<IshiCard> get currentHand =>
      _manager.playerHands[_manager.localPlayerIndex];

  IshiCard? _selectedCard;
  bool _showDevConsole = false;
  bool _showDevConsoleToggle = false;
  bool _isViewingRelics = false;

  Relic? _activeTargetingRelic;
  final List<IshiCard> _relicTargets = [];

  List<IshiCard> _initialHandBuffer = [];

  late Timer _hostTurnTimer;

  List<CombatMessage> _currentCombatMessages = [];
  Key _combatMessagesKey = UniqueKey();
  final List<CombatMessage> _newMessages = [];

  void updateUI(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _startOpeningSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1st Broadcast: Host sends the starting state.
    // Clients receive their cards and instantly start staggering!
    if (_net.isHost) broadcastGameState();

    // Host staggers their own intercepted hand back into the UI
    if (_initialHandBuffer.isNotEmpty) {
      await _staggerDrawCards(_initialHandBuffer);
      _triggerAutoSortIfNeeded();
    }

    // 2nd Broadcast: Tell clients the Host finished dealing.
    // This causes the face-down cards to instantly pop into the opponent overlay!
    if (_net.isHost) broadcastGameState();
  }

  @override
  void initState() {
    super.initState();
    _manager = widget.manager;

    listKeys = {};
    scrollControllers = {};
    for (int i = 1; i <= _manager.playerCount; i++) {
      listKeys[i] = GlobalKey<AnimatedListState>();
      scrollControllers[i] = ScrollController();
    }

    if (_net.isHost && _manager.playerHands.isNotEmpty) {
      _initialHandBuffer = List.from(
        _manager.playerHands[_manager.localPlayerIndex],
      );
      _manager.playerHands[_manager.localPlayerIndex].clear();
    }

    initializeNetworkSync();

    _hostTurnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_net.isHost || _manager.winnerIndex != null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= _manager.turnDeadlineEpoch) {
        updateUI(() => _manager.endTurn());
        broadcastGameState();
      }
    });

    _manager.onChaosTrigger = _onChaosTrigger;
    _manager.onWildBuffTrigger = _onWildBuffTrigger;
    _manager.onEvolvedTrigger = _onEvolvedTrigger;
    _manager.onFrozenTrigger = _onFrozenTrigger;

    DevConsole().initialize(_manager, _net);
    DevConsole().onStateForceSynced = () {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < listKeys.length; i++) {
          listKeys[i] = GlobalKey<AnimatedListState>();
        }
      });
      if (_net.isHost) broadcastGameState();
    };

    AudioManager().playMusic(Audio.music.gameLoop1);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _startOpeningSequence(),
    );
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    _pingSubscription?.cancel();
    _gameEventSubscription?.cancel();
    _hostTurnTimer.cancel();
    for (ScrollController controller in scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
    AudioManager().playMusic(Audio.music.menuLoop1);
  }

  @override
  Widget build(BuildContext context) {
    final stackedContent = [
      // Local Player Info & Ping
      Positioned(
        top: 16,
        left: 16,
        child: PingToggleButton(
          showPingOverlay: _showPingOverlay,
          onToggle: () => setState(() => _showPingOverlay = !_showPingOverlay),
          onLongPress: () => showDialog(
            context: context,
            builder: (_) => DevConsoleToggleDialog(
              showDevConsole: _showDevConsoleToggle,
              onToggle: (val) => setState(() => _showDevConsoleToggle = val),
            ),
          ),
        ),
      ),

      // Round Indicator
      Positioned(
        top: 24,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const .symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: .circular(16),
              border: .all(color: Colors.white24, width: 1),
            ),
            child: Text(
              "ROUND ${_manager.roundCount}",
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: .bold,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),

      // Top Right Settings
      Positioned(top: 16, right: 16, child: _topRightButtonRow(context)),

      // Opponent Hands Overlay
      Positioned(
        top: 64,
        right: 16,
        child: OpponentsOverlay(
          manager: _manager,
          net: _net,
          listKeys: listKeys,
        ),
      ),

      // Game Board
      Positioned(
        top: (MediaQuery.of(context).size.height / 2) - 128,
        left: 0,
        right: 0,
        child: _playPileAndDeck(),
      ),

      // Turn Indicator
      Positioned(
        top: 194,
        left: 0,
        right: 0,
        child: TurnIndicator(
          isMyTurn: isMyTurn,
          turnDeadlineEpoch: _manager.turnDeadlineEpoch,
        ),
      ),

      // Local Hand
      Align(alignment: .bottomCenter, child: _lowerPanel()),

      // Turn Timeline
      Positioned(
        left: 0,
        right: 0,
        bottom: 32,
        child: TurnTimeline(manager: _manager, net: _net),
      ),

      // Overlays
      Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: PlayerInfo(manager: _manager, network: _net),
      ),
      if (_showPingOverlay)
        Positioned(top: 64, left: 16, child: LivePingPanel(network: _net)),
      if (_showDevConsole)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DevConsoleOverlay(
            onClose: () => setState(() => _showDevConsole = false),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(child: Stack(children: stackedContent)),
    );
  }

  // THE PLAY PILE (Center)
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

        setState(() {
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
      onPressed: () => setState(() => _isViewingRelics = !_isViewingRelics),
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
              onToggleAutoSort: () => setState(
                () => _manager.isAutoSortEnabled = !_manager.isAutoSortEnabled,
              ),
              manager: _manager,
              isMyTurn: isMyTurn,
            ),
          ),
          AnimatedPlayButton(
            selectedCard: _selectedCard,
            isMyTurn: isMyTurn,
            onPlay: () => playCardAction(_selectedCard!),
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
          onPressed: () => setState(() {
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

  Row _topRightButtonRow(BuildContext context) {
    final buttons = [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const SettingsDialog()
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ),
        icon: const Icon(Icons.settings, color: Colors.white70, size: 30),
        tooltip: "Show Settings",
      ),
      if (_showDevConsoleToggle)
        IconButton(
          onPressed: () => setState(() => _showDevConsole = !_showDevConsole),
          icon: const Icon(Icons.terminal, color: Colors.greenAccent),
          tooltip: "Show Developer Console",
        ),
      IconButton(
        onPressed: _promptLeaveGame,
        icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 30),
        tooltip: "Exit Match",
      ),
    ];
    return Row(mainAxisSize: .min, children: buttons);
  }

  void _promptLeaveGame() => showDialog(
    context: context,
    builder: (_) => LeaveGameDialog(network: _net)
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
  );

  Widget _buildRelicDisplay() => RelicDisplay(
    relics: _manager.playerRelics[_manager.localPlayerIndex],
    onTapRelic: (isActiveRelic, relic) {
      if (!isMyTurn || !isActiveRelic) return;
      setState(() {
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

    if (_newMessages.isEmpty) return;
    updateUI(() {
      _currentCombatMessages = List.from(_newMessages);
      _combatMessagesKey = UniqueKey();
    });
    _newMessages.clear();
  }
}
