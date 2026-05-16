import 'dart:async';
import 'package:ishi/core/network_messages.dart';

abstract class NetworkService {
  bool get isHost;
  bool get isConnected;
  int get currentPlayer;
  List<LobbyPlayer> get playersList;
  Stream<NetMessage> get messages;

  // WebRTC uses this, SocketService will just return null
  String? get currentRoomCode;

  void sendToClient(int clientIndex, NetMessage message);
  void broadcast(NetMessage message);
  void sendIntent(NetMessage message);
  void kickPlayer(int playerIndex, {String? reason});
  void purgeInvalidPlayers();
  Future<void> disconnect();
}
