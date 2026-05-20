import 'package:flutter/material.dart';
import 'package:ishi/services/network_service.dart';

class LobbyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LobbyAppBar({super.key, required this.net});

  final NetworkService net;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: BackButton(
      color: Colors.white,
      onPressed: () async {
        await net.disconnect();
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
      if (net.isHost) _PurgeButton(onPressed: () => net.purgeInvalidPlayers()),
    ],
  );
}

class _PurgeButton extends StatelessWidget {
  const _PurgeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(
      Icons.cleaning_services_rounded,
      color: Colors.orangeAccent,
    ),
    tooltip: "Purge Invalid Players",
    onPressed: onPressed,
  );
}
