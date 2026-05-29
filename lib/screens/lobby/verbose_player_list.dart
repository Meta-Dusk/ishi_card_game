import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/dialogs/menus/kick_confirmation_dialog.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/core/network/network_messages.dart';

class VerbosePlayerList extends StatelessWidget {
  const VerbosePlayerList({super.key, required this.players, this.onKick});

  final List<LobbyPlayer> players;
  final void Function(int playerIndex, {String? reason})? onKick;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: players.length,
    itemBuilder: (_, index) {
      final delay = 100.ms * (index + 1);
      return _PlayerListEntry(index: index, players: players, onKick: onKick)
          .animate()
          .fadeIn(delay: delay, duration: 200.ms)
          .slideY(
            delay: delay + 200.ms,
            begin: -0.5,
            curve: Curves.easeOutCubic,
          );
    },
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
  final void Function(int playerIndex, {String? reason})? onKick;

  LobbyPlayer get player => players[index];
  bool get isHost => index == 0;
  int get ping => player.pingMs;

  Color get pingColor => ping < 60
      ? Colors.greenAccent
      : (ping < 150 ? Colors.amber : Colors.redAccent);

  IconData get pingIcon => ping < 60
      ? Icons.wifi
      : (ping < 150 ? Icons.wifi_2_bar : Icons.wifi_1_bar);

  Color get playerAvatarColor =>
      ProfileManager().getAvatarColor(player.avatarColorName);

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.grey.shade800,
    margin: const .only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: .circular(12)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: playerAvatarColor,
        child: Tooltip(
          message: isHost ? "The host" : "You're not the host :)",
          triggerMode: .tap,
          preferBelow: true,
          child: Icon(isHost ? Icons.star : Icons.person, color: Colors.white),
        ),
      ),
      title: Text(
        player.playerName,
        style: const TextStyle(color: Colors.white, fontWeight: .bold),
      ),
      trailing: Row(mainAxisSize: .min, children: _trailingContent),
    ),
  );

  List<Widget> get _trailingContent => [
    if (onKick != null && index != 0) ...[
      _KickButton(onKick: onKick, index: index, player: player),
      const SizedBox(width: 16),
    ],
    _TrailingPingIcon(pingIcon: pingIcon, pingColor: pingColor, ping: ping),
  ];
}

class _KickButton extends StatelessWidget {
  const _KickButton({
    required this.onKick,
    required this.index,
    required this.player,
  });

  final void Function(int playerIndex, {String? reason})? onKick;
  final int index;
  final LobbyPlayer player;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => showDialog(
      context: context,
      builder: (_) => KickConfirmationDialog(
        player: player,
        textController: TextEditingController(),
        onKick: onKick,
        playerIndex: index,
      ),
    ),
    icon: const Icon(Icons.person_remove, color: Colors.redAccent),
    tooltip: "Kick ${player.playerName}",
  );
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
  Widget build(BuildContext context) => Column(
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
