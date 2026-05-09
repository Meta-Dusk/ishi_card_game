import 'dart:async';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import '../services/socket_service.dart';
import 'game_screen/game_screen.dart';

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

    _socketSubscription = _socket.messages.listen((message) {
      if (!mounted) return;

      // UNIFIED LOBBY SYNC
      // Whenever the host sends an update, just grab the truth from the socket!
      switch (message) {
        // Any message that changes the player count updates the UI
        case PlayerJoinedMessage(:final totalPlayers):
        case LobbySyncResponseMessage(:final totalPlayers):
          setState(() => _connectedPlayers = totalPlayers);
          break;

        case LobbyStateMessage():
          // The socket service automatically updates its playersList,
          // we just need to trigger a UI rebuild to paint it!
          setState(() => _connectedPlayers = _socket.currentPlayers);
          break;

        case GameStateMessage(:final payload):
          final localManager = GameManager(
            playerCount: _socket.currentPlayers,
            startingHandSize: 7,
          );
          // Pass the unpacked payload directly to the engine
          localManager.applyGameStateJson(payload);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(manager: localManager),
            ),
          );
          break;

        default:
          break;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_socket.isHost) return;
      _socket.sendIntent(const RequestLobbyStateMessage(0));
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
      _socket.sendToClient(i - 1, GameStateMessage(personalizedState));
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(manager: masterManager)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = _socket.playersList;

    final mainContent = [
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
      Center(child: _socket.isHost ? _startGameButton() : _clientView()),
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

  Widget _clientView() => Container(
    padding: const .all(16),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: .circular(12),
    ),
    child: const Row(
      mainAxisSize: .min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.orangeAccent,
            strokeWidth: 3,
          ),
        ),
        SizedBox(width: 16),
        Text(
          "Waiting for Host to start...",
          style: TextStyle(color: Colors.white70, fontWeight: .bold),
        ),
      ],
    ),
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

class VerbosePlayerList extends StatelessWidget {
  const VerbosePlayerList({super.key, required this.players});

  final List<LobbyPlayer> players;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: players.length,
        itemBuilder: (_, index) =>
            _PlayerListEntry(index: index, players: players),
      ),
    );
  }
}

class _PlayerListEntry extends StatelessWidget {
  const _PlayerListEntry({required this.index, required this.players});

  final int index;
  final List<LobbyPlayer> players;

  @override
  Widget build(BuildContext context) {
    final player = players[index];
    final isHost = index == 0;
    final ping = player.pingMs;

    Color pingColor = ping < 60
        ? Colors.greenAccent
        : (ping < 150 ? Colors.amber : Colors.redAccent);
    IconData pingIcon = ping < 60
        ? Icons.wifi
        : (ping < 150 ? Icons.wifi_2_bar : Icons.wifi_1_bar);

    return Card(
      color: Colors.grey.shade800,
      margin: const .only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(player.avatarColor),
          child: Icon(isHost ? Icons.star : Icons.person, color: Colors.white),
        ),
        title: Text(
          player.playerName,
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        trailing: _trailingPingIcon(pingIcon, pingColor, ping),
      ),
    );
  }

  Column _trailingPingIcon(IconData pingIcon, Color pingColor, int ping) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .end,
      children: [
        Icon(pingIcon, color: pingColor, size: 20),
        Text(
          "${ping}ms",
          style: TextStyle(color: pingColor, fontSize: 12, fontWeight: .bold),
        ),
      ],
    );
  }
}
