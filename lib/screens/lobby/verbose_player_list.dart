import 'package:flutter/material.dart';
import 'package:ishi/components/dialogs/kick_confirmation_dialog.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/core/network_messages.dart';

class VerbosePlayerList extends StatelessWidget {
  const VerbosePlayerList({super.key, required this.players, this.onKick});

  final List<LobbyPlayer> players;
  final void Function(int, {String? reason})? onKick;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: players.length,
    itemBuilder: (_, index) =>
        _PlayerListEntry(index: index, players: players, onKick: onKick),
  );
}

class _PlayerListEntry extends StatelessWidget {
  const _PlayerListEntry({
    required this.index,
    required this.players,
    this.onKick,
  });

  final int index;
  final List<LobbyPlayer> players;
  final void Function(int, {String? reason})? onKick;

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

    final trailingContent = [
      if (onKick != null && index != 0) ...[
        _KickButton(onKick: onKick, index: index, player: player),
        const SizedBox(width: 16),
      ],
      _TrailingPingIcon(pingIcon: pingIcon, pingColor: pingColor, ping: ping),
    ];

    return Card(
      color: Colors.grey.shade800,
      margin: const .only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ProfileManager().getAvatarColor(
            player.avatarColorName,
          ),
          child: Icon(isHost ? Icons.star : Icons.person, color: Colors.white),
        ),
        title: Text(
          player.playerName,
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        trailing: Row(mainAxisSize: .min, children: trailingContent),
      ),
    );
  }
}

class _KickButton extends StatelessWidget {
  const _KickButton({
    required this.onKick,
    required this.index,
    required this.player,
  });

  final void Function(int, {String? reason})? onKick;
  final int index;
  final LobbyPlayer player;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        final controller = TextEditingController();
        showDialog(
          context: context,
          builder: (_) => KickConfirmationDialog(
            player: player,
            textController: controller,
            onKick: onKick,
            playerIndex: index,
          ),
        );
      },
      icon: const Icon(Icons.person_remove, color: Colors.redAccent),
      tooltip: "Kick ${player.playerName}",
    );
  }
}

class _TrailingPingIcon extends StatelessWidget {
  const _TrailingPingIcon({
    required this.pingIcon,
    required this.pingColor,
    required this.ping,
  });

  final IconData pingIcon;
  final Color pingColor;
  final int ping;

  @override
  Widget build(BuildContext context) {
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
