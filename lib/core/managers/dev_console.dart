import 'dart:ui';

import 'package:ishi/core/managers/dev_commands.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';

class DevCommand {
  final String name;
  final String description;
  final void Function(List<String> args) onExecute;

  DevCommand({
    required this.name,
    required this.description,
    required this.onExecute,
  });
}

class DevConsole {
  static final DevConsole _instance = DevConsole._internal();
  factory DevConsole() => _instance;
  DevConsole._internal();

  final List<String> logs = [
    "Ishi Dev Console v1.0",
    "Type 'help' for commands.",
  ];
  final List<DevCommand> _commands = [];

  /// Used to trigger UI updates when a log is added.
  VoidCallback? onLogAdded;

  VoidCallback? onExit;
  VoidCallback? onStateForceSynced;

  void log(String message) {
    logs.add("> $message");
    onLogAdded?.call();
  }

  void dispose() {
    onLogAdded = null;
    onExit = null;
    onStateForceSynced = null;
  }

  /// Registers all the dev commands.
  void initialize(GameManager manager, NetworkService net) {
    _commands.clear();
    _commands.addAll(
      DevCommandRegistry.buildCommands(
        manager: manager,
        net: net,
        console: this,
        allCommandsRef: _commands,
      ),
    );
  }

  /// Parses the input and runs the command.
  void execute(String input) {
    if (input.trim().isEmpty) return;
    log(input);

    List<String> parts = input.trim().split(" ");
    String commandName = parts.first.toLowerCase();
    List<String> args = parts.length > 1 ? parts.sublist(1) : [];

    try {
      final command = _commands.firstWhere((c) => c.name == commandName);
      command.onExecute(args);
    } catch (e) {
      log("Unknown command: '$commandName'. Type 'help'.");
    }
  }

  /// Returns command suggestions for the Autocomplete widget.
  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    String qry = query.toLowerCase();

    List<String> matches = [];

    // Suggest main commands (e.g., typing "ca" suggests "card")
    for (DevCommand cmd in _commands) {
      if (cmd.name.startsWith(qry)) {
        matches.add(cmd.name);
      }
    }

    // Suggest specific sub-arguments!
    if (qry.startsWith("card ")) {
      if ("card draw".startsWith(qry)) matches.add("card draw");
      if ("card remove".startsWith(qry)) matches.add("card remove");
    }
    if (qry.startsWith("deck ")) {
      if ("deck add".startsWith(qry)) matches.add("deck add");
      if ("deck remove".startsWith(qry)) matches.add("deck remove");
    }
    if (qry.startsWith("pile ")) {
      if ("pile add".startsWith(qry)) matches.add("pile add");
      if ("pile remove".startsWith(qry)) matches.add("pile remove");
    }
    if (qry.startsWith("sortby ")) {
      if ("sortby color".startsWith(qry)) matches.add("sortby color");
      if ("sortby type".startsWith(qry)) matches.add("sortby type");
      if ("sortby value".startsWith(qry)) matches.add("sortby value");
      if ("sortby unsorted".startsWith(qry)) matches.add("sortby unsorted");
    }

    return matches;
  }
}
