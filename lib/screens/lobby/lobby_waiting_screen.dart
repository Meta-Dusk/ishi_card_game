import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ishi/services/webrtc_service.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/network_messages.dart';
import '../game_screen/game_screen.dart';
import 'verbose_player_list.dart';
import 'client_view.dart';
import 'room_code_view.dart';

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

  int get getConnectedPlayerCount => _net.currentPlayers;

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

  void _processNetMessage(NetMessage message) {
    if (!mounted) return;

    switch (message) {
      // Any message that changes the player count updates the UI
      case PlayerJoinedMessage(:final totalPlayers):
      case LobbySyncResponseMessage(:final totalPlayers):
        setState(() => _connectedPlayers = totalPlayers);
        break;

      case LobbyStateMessage():
        // The socket service automatically updates its playersList,
        // we just need to trigger a UI rebuild to paint it!
        setState(() => _connectedPlayers = _net.currentPlayers);
        break;

      case GameStateMessage(:final payload):
        final localManager = GameManager(
          playerCount: _net.currentPlayers,
          startingHandSize: 7,
        );
        // Pass the unpacked payload directly to the engine
        localManager.applyGameStateJson(payload);

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

  void _onStartGame() {
    // Host builds and initializes the master engine
    final masterManager = GameManager(
      playerCount: getConnectedPlayerCount,
      startingHandSize: 7,
    );
    masterManager.initializeGame();

    // Host deals the cards. (This JSON acts as the Start signal for clients!)
    for (int i = 1; i < getConnectedPlayerCount; i++) {
      final personalizedState = masterManager.generateGameStateJson(i);
      _net.sendToClient(i - 1, GameStateMessage(personalizedState));
    }

    if (_net is WebRTCService) (_net as WebRTCService).lockLobby();

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

    final mainContent = [
      if (roomCode != null) ...[
        RoomCodeView(roomCode: roomCode),
        const SizedBox(height: 24),
      ],
      Text(
        "PLAYERS CONNECTED: $_connectedPlayers/10",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: .bold,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 16),
      VerbosePlayerList(players: players),
      const SizedBox(height: 20),
      Center(
        child: _net.isHost
            ? _StartGameButton(onStartGame: _onStartGame)
            : ClientView(),
      ),
      const SizedBox(height: 20),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "LOBBY",
          style: TextStyle(
            fontWeight: .bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const .all(16.0),
        child: Column(crossAxisAlignment: .start, children: mainContent),
      ),
    );
  }
}

class _StartGameButton extends StatelessWidget {
  const _StartGameButton({required this.onStartGame});

  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const .symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: onStartGame,
      icon: const Icon(Icons.play_arrow),
      label: const Text(
        "START MATCH",
        style: TextStyle(fontSize: 18, fontWeight: .bold),
      ),
    );
  }
}
