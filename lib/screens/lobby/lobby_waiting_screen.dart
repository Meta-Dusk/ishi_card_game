import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/dialogs/menus/on_kicked_dialog.dart';
import 'package:ishi/screens/game_screen/imports/game_components.dart';
import 'package:ishi/screens/lobby/loading_screen.dart';
import 'package:ishi/screens/lobby/lobby_app_bar.dart';
import 'package:ishi/screens/lobby/settings/lobby_settings.dart';
import 'package:ishi/screens/main_menu/main_menu_screen.dart';
import 'package:ishi/services/webrtc_service.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/network/network_messages.dart';
import '../game_screen/game_screen.dart';
import 'verbose_player_list.dart';
import 'client_view.dart';
import 'room_code_view.dart';
import 'start_game_button.dart';

class LobbyWaitingScreen extends StatefulWidget {
  final NetworkService network;
  final MainMenuScreenState menu;

  const LobbyWaitingScreen({
    super.key,
    required this.network,
    required this.menu,
  });

  @override
  State<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends State<LobbyWaitingScreen> {
  NetworkService get _net => widget.network;

  int _connectedPlayers = 1;
  StreamSubscription? _netSubscription;
  String? get roomCode => _net.currentRoomCode;

  int get getConnectedPlayerCount => _net.currentPlayer;

  int _startingHandSize = 7;
  int _maxPlayers = 4;
  bool _isStartingGame = false;

  List<LobbyPlayer> get players => _net.playersList;

  @override
  void initState() {
    super.initState();
    _connectedPlayers = getConnectedPlayerCount;

    _netSubscription = _net.messages.listen(
      (message) => _processNetworkMessage(message),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_net.isHost) return;
      _net.sendIntent(const RequestLobbyStateMessage(0));
    });
  }

  void _processNetworkMessage(NetMessage message) async {
    if (!mounted) return;

    switch (message) {
      case LobbySettingsMessage(:final startingHandSize, :final maxPlayers):
        setState(() {
          _startingHandSize = startingHandSize;
          _maxPlayers = maxPlayers;
        });
        break;

      case KickedMessage(:final reason):
        _net.disconnect();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => OnKickedDialog(reason: reason),
        );
        break;

      case SystemNotificationMessage(:final text):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text, style: const TextStyle(fontWeight: .bold)),
            backgroundColor: Colors.blueGrey.shade800,
            duration: const Duration(seconds: 3),
            behavior: .floating,
          ),
        );
        break;

      // Any message that changes the player count updates the UI
      case PlayerJoinedMessage(:final totalPlayers):
      case LobbySyncResponseMessage(:final totalPlayers):
        setState(() => _connectedPlayers = totalPlayers);

        if (!_net.isHost) break;
        if (totalPlayers > _maxPlayers) {
          _net.kickPlayer(
            totalPlayers - 1,
            reason:
                "Lobby is full! Current capacity: $totalPlayers/$_maxPlayers",
          );
        } else {
          _net.broadcast(LobbySettingsMessage(_startingHandSize, _maxPlayers));
        }
        break;

      case LobbyStateMessage():
        // The socket service automatically updates its playersList,
        // we just need to trigger a UI rebuild to paint it!
        setState(() => _connectedPlayers = _net.currentPlayer);
        break;

      case GameStateMessage(:final payload):
        setState(() => _isStartingGame = true);
        await Future.delayed(const Duration(milliseconds: 150));

        final localManager = GameManager(
          playerCount: _net.currentPlayer,
          startingHandSize: _startingHandSize,
        );
        // Pass the unpacked payload directly to the engine
        localManager.applyGameState(payload);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              manager: localManager,
              network: _net,
              menu: widget.menu,
            ),
          ),
        );
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    super.dispose();
  }

  void _onStartGame() async {
    setState(() => _isStartingGame = true);
    await Future.delayed(150.ms);

    // Host builds and initializes the master engine
    final masterManager = GameManager(
      playerCount: getConnectedPlayerCount,
      startingHandSize: _startingHandSize,
    );
    masterManager.initializeGame();

    // Host deals the cards. (This JSON acts as the Start signal for clients!)
    for (int i = 1; i < getConnectedPlayerCount; i++) {
      final personalizedState = masterManager.generateGameState(i);
      _net.sendToClient(i - 1, GameStateMessage(personalizedState));
    }

    if (_net is WebRTCService) (_net as WebRTCService).lockLobby();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          manager: masterManager,
          network: _net,
          menu: widget.menu,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      await _net.disconnect();
      if (context.mounted) Navigator.of(context).pop();
    },
    child: Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: LobbyAppBar(net: _net),
      body: AnimatedGradientBackground(
        colors: [Colors.grey.shade800, Colors.grey.shade900, Colors.black],
        duration: const Duration(seconds: 120),
        animationType: .spin,
        child: Stack(children: _stackedContent(_getMainContent(players))),
      ),
    ),
  );

  List<Widget> _getMainContent(List<LobbyPlayer> players) => _mainContent(
    _PlayerCountLabel(
      connectedPlayers: _connectedPlayers,
      maxPlayers: _maxPlayers,
    ),
    VerbosePlayerList(
      players: players,
      onKick: _net.isHost
          ? (index, {reason}) => _net.kickPlayer(index, reason: reason)
          : null,
    ),
  );

  List<Widget> _mainContent(
    Widget playerCountLabel,
    VerbosePlayerList verbosePlayerList,
  ) => [
    if (roomCode != null) ...[
      RoomCodeView(roomCode: roomCode)
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
      const SizedBox(height: 24),
    ],
    playerCountLabel
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(delay: 200.ms, begin: -0.5, curve: Curves.easeOutCubic),
    const SizedBox(height: 16),
    Expanded(
      child: verbosePlayerList
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(delay: 300.ms, begin: -0.5, curve: Curves.easeOutCubic),
    ),
    const SizedBox(height: 16),
    LobbySettings(
      network: _net,
      startingHandSize: _startingHandSize,
      maxPlayers: _maxPlayers,
      connectedPlayers: _connectedPlayers,
      onHandSizeChanged: (val) => setState(() => _startingHandSize = val),
      onMaxPlayersChanged: (val) => setState(() => _maxPlayers = val),
      onSettingsChangeEnd: () =>
          _net.broadcast(LobbySettingsMessage(_startingHandSize, _maxPlayers)),
    ),
    const SizedBox(height: 20),
    Center(
      child: _net.isHost
          ? StartGameButton(onStartGame: _onStartGame)
          : ClientView(),
    ),
    const SizedBox(height: 20),
  ];

  List<Widget> _stackedContent(List<Widget> mainContent) => [
    Padding(
      padding: const .all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        children: mainContent
            .animate(interval: 100.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutCubic),
      ),
    ),
    if (_isStartingGame) LoadingScreen().animate().fadeIn(duration: 200.ms),
  ];
}

class _PlayerCountLabel extends StatelessWidget {
  const _PlayerCountLabel({
    required this.connectedPlayers,
    required this.maxPlayers,
  });

  final int connectedPlayers;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) => Text(
    "PLAYERS CONNECTED: $connectedPlayers/$maxPlayers",
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontWeight: .bold,
      letterSpacing: 1.5,
    ),
  );
}
