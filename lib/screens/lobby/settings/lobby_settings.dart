import 'package:flutter/material.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/services/webrtc_service.dart';
import 'client_view.dart';
import 'host_view.dart';

class LobbySettings extends StatelessWidget {
  final NetworkService network;

  final int startingHandSize;
  final int maxPlayers;
  final int connectedPlayers;

  final ValueChanged<int> onHandSizeChanged;
  final ValueChanged<int> onMaxPlayersChanged;
  final VoidCallback onSettingsChangeEnd;

  const LobbySettings({
    super.key,
    required this.network,
    required this.startingHandSize,
    required this.maxPlayers,
    required this.connectedPlayers,
    required this.onHandSizeChanged,
    required this.onMaxPlayersChanged,
    required this.onSettingsChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    int absoluteMaxPlayers = network is WebRTCService ? 10 : 15;

    if (!network.isHost) {
      return ClientView(
        startingHandSize: startingHandSize,
        maxPlayers: maxPlayers,
      );
    }

    return HostView(
      startingHandSize: startingHandSize,
      onHandSizeChanged: onHandSizeChanged,
      onSettingsChangeEnd: onSettingsChangeEnd,
      maxPlayers: maxPlayers,
      absoluteMaxPlayers: absoluteMaxPlayers,
      connectedPlayers: connectedPlayers,
      onMaxPlayersChanged: onMaxPlayersChanged,
    );
  }
}
