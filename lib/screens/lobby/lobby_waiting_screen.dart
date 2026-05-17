import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/dialogs/on_kicked_dialog.dart';
import 'package:ishi/screens/lobby/settings/lobby_settings.dart';
import 'package:ishi/services/webrtc_service.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/network_messages.dart';
import '../game_screen/game_screen.dart';
import 'verbose_player_list.dart';
import 'client_view.dart';
import 'room_code_view.dart';
import 'start_game_button.dart';

class LobbyWaitingScreen extends StatefulWidget {
  final NetworkService network;

  const LobbyWaitingScreen({super.key, required this.network});

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
  int _maxPlayers = 10;
  bool _isStartingGame = false;

  @override
  void initState() {
    super.initState();
    _connectedPlayers = getConnectedPlayerCount;

    _netSubscription = _net.messages.listen(
      (message) => _processNetMessage(message),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_net.isHost) return;
      _net.sendIntent(const RequestLobbyStateMessage(0));
    });
  }

  void _processNetMessage(NetMessage message) async {
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
        await Future.delayed(150.ms);

        final localManager = GameManager(
          playerCount: _net.currentPlayer,
          startingHandSize: _startingHandSize,
        );
        // Pass the unpacked payload directly to the engine
        localManager.applyGameStateJson(payload);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(manager: localManager, network: _net),
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
      final personalizedState = masterManager.generateGameStateJson(i);
      _net.sendToClient(i - 1, GameStateMessage(personalizedState));
    }

    if (_net is WebRTCService) (_net as WebRTCService).lockLobby();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(manager: masterManager, network: _net),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = _net.playersList;

    final verbosePlayerList = VerbosePlayerList(
      players: players,
      onKick: _net.isHost
          ? (index, {reason}) => _net.kickPlayer(index, reason: reason)
          : null,
    );

    final playerCountLabel = Text(
      "PLAYERS CONNECTED: $_connectedPlayers/$_maxPlayers",
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: .bold,
        letterSpacing: 1.5,
      ),
    );

    final mainContent = [
      if (roomCode != null) ...[
        RoomCodeView(roomCode: roomCode)
            .animate()
            .fadeIn(duration: 100.ms)
            .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
        const SizedBox(height: 24),
      ],
      playerCountLabel
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
      const SizedBox(height: 16),
      Expanded(
        child: verbosePlayerList
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
      ),
      const SizedBox(height: 16),
      LobbySettings(
        network: _net,
        startingHandSize: _startingHandSize,
        maxPlayers: _maxPlayers,
        connectedPlayers: _connectedPlayers,
        onHandSizeChanged: (val) => setState(() => _startingHandSize = val),
        onMaxPlayersChanged: (val) => setState(() => _maxPlayers = val),
        onSettingsChangeEnd: () => _net.broadcast(
          LobbySettingsMessage(_startingHandSize, _maxPlayers),
        ), // Blast the network packet ONLY when the slider drag ends!
      ),
      const SizedBox(height: 20),
      Center(
        child: _net.isHost
            ? StartGameButton(onStartGame: _onStartGame)
            : ClientView(),
      ),
      const SizedBox(height: 20),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () async {
            await _net.disconnect();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: const Text(
          "LOBBY",
          style: TextStyle(
            fontWeight: .bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_net.isHost)
            IconButton(
              icon: const Icon(
                Icons.cleaning_services_rounded,
                color: Colors.orangeAccent,
              ),
              tooltip: "Purge Invalid Players",
              onPressed: () => _net.purgeInvalidPlayers(),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const .all(16.0),
            child: Column(crossAxisAlignment: .start, children: mainContent)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, curve: Curves.easeOutCubic),
          ),
          if (_isStartingGame)
            LoadingScreen().animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 6),
      SizedBox(height: 24),
      Text(
        "SHUFFLING DECK...",
        style: TextStyle(
          color: Colors.white,
          fontWeight: .bold,
          fontSize: 18,
          letterSpacing: 2.0,
        ),
      ),
    ];

    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          children: mainContent
              .animate(interval: 100.ms)
              .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}
