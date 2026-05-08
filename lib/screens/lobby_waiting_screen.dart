import 'dart:async';
import 'package:esther_gift/managers/game_manager.dart';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'game_screen/game_screen.dart';
import '../core/network_keys.dart';

class LobbyWaitingScreen extends StatefulWidget {
  const LobbyWaitingScreen({super.key});

  @override
  State<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends State<LobbyWaitingScreen> {
  final SocketService _socket = SocketService();
  int _connectedPlayers = 1;
  StreamSubscription? _socketSubscription;

  int get getConnectedPlayerCount => _socket.currentPlayers;

  @override
  void initState() {
    super.initState();
    _connectedPlayers = _socket.currentPlayers;

    _socketSubscription = _socket.messages.listen((data) {
      if (!mounted) return;

      // LOBBY SYNC
      if (data[NetKey.type] == NetKey.playerJoined) {
        setState(() {
          if (data.containsKey(NetKey.totalPlayers)) {
            _connectedPlayers = data[NetKey.totalPlayers];
          } else {
            _connectedPlayers = (data[NetKey.clientCount] as int) + 1;
          }
        });
      }

      if (data[NetKey.type] == NetKey.gameStateUpdate) {
        final localManager = GameManager(
          playerCount: _connectedPlayers,
          startingHandSize: 7,
        );
        localManager.applyGameStateJson(data);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GameScreen(manager: localManager)),
        );
      }

      // HOST SYNC
      if (data[NetKey.type] == NetKey.lobbySyncResponse) {
        setState(() => _connectedPlayers = data[NetKey.totalPlayers]);
      }

      if (_socket.isHost &&
          (data[NetKey.type] == NetKey.requestLobbyState ||
              data[NetKey.type] == NetKey.requestLobbyState)) {
        _socket.broadcast({
          NetKey.type: NetKey.lobbySyncResponse,
          NetKey.totalPlayers: _connectedPlayers,
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_socket.isHost) return;
      _socket.sendIntent({NetKey.type: NetKey.requestLobbyState});
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
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
      _socket.sendToClient(i - 1, personalizedState);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(manager: masterManager)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Icon(Icons.router, size: 80, color: Colors.greenAccent),
      const SizedBox(height: 20),
      Text(
        "PLAYERS CONNECTED: $_connectedPlayers",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: .bold,
        ),
      ),
      const SizedBox(height: 40),

      if (_socket.isHost) _startGameButton() else _clientView(),
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
      body: Center(
        child: Column(mainAxisAlignment: .center, children: mainContent),
      ),
    );
  }

  Column _clientView() => const Column(
    children: [
      CircularProgressIndicator(color: Colors.orangeAccent),
      SizedBox(height: 20),
      Text(
        "Waiting for Host to start...",
        style: TextStyle(color: Colors.grey),
      ),
    ],
  );

  ElevatedButton _startGameButton() => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      padding: const .symmetric(horizontal: 40, vertical: 16),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    onPressed: _onStartGame,
    icon: const Icon(Icons.play_arrow),
    label: const Text(
      "START MATCH",
      style: TextStyle(fontSize: 18, fontWeight: .bold),
    ),
  );
}
