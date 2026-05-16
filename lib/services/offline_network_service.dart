import 'dart:async';
import '../core/network_messages.dart';
import '../core/managers/profile_manager.dart';
import 'network_service.dart';

class OfflineNetworkService implements NetworkService {
  final _messageController = StreamController<NetMessage>.broadcast();

  @override
  final int currentPlayer;

  @override
  late final List<LobbyPlayer> playersList;

  // In offline mode, the local device is ALWAYS the host!
  @override
  bool get isHost => true;

  @override
  bool get isConnected => true;

  @override
  String? get currentRoomCode => null;

  @override
  Stream<NetMessage> get messages => _messageController.stream;

  OfflineNetworkService({required this.currentPlayer}) {
    // Automatically generate the local players/bots list
    playersList = List.generate(currentPlayer, (index) {
      if (index == 0) {
        return LobbyPlayer(
          playerName: ProfileManager().playerName,
          avatarColorName: ProfileManager().avatarColorName,
          pingMs: 0,
        );
      }
      return LobbyPlayer(playerName: "Player ${index + 1}", pingMs: 0);
    });
  }

  @override
  void broadcast(NetMessage message) {
    // Instantly loop the broadcast back to the local UI
    _messageController.add(message);
  }

  @override
  void sendToClient(int clientIndex, NetMessage message) {
    // In couch co-op, everything is on one screen, so just loop it back!
    _messageController.add(message);
  }

  @override
  void sendIntent(NetMessage message) {
    // When the local player taps a card, instantly route the intent
    // to the local Host listener!
    _messageController.add(message);
  }

  @override
  void kickPlayer(int playerIndex, {String? reason}) {
    playersList.remove(playersList[playerIndex]);
  }

  @override
  void purgeInvalidPlayers() {}

  @override
  Future<void> disconnect() async {
    _messageController.close();
  }
}
