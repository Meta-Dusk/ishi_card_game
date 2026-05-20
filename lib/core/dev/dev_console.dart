import 'dart:ui';

import 'package:ishi/core/dev/dev_commands.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/services/network_service.dart';

class DevCommand {
  final String name;
  final String description;
  final String? usage;
  final void Function(List<String> args, String? usage) onExecute;

  DevCommand({
    required this.name,
    required this.description,
    this.usage,
    required this.onExecute,
  });
}

class DevConsole {
  static final DevConsole _instance = DevConsole._internal();
  factory DevConsole() => _instance;
  DevConsole._internal();

  final List<String> logs = [
    "Ishi Dev Console v2.0",
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
    String commandName = parts.first;
    List<String> args = parts.length > 1 ? parts.sublist(1) : [];

    try {
      final command = _commands.firstWhere((c) => c.name == commandName);
      command.onExecute(args, command.usage);
    } catch (e) {
      log("Unknown command: '$commandName'. Type 'help'.");
    }
  }

  /// Returns command suggestions for the Autocomplete widget.
  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    List<String> matches = [];

    // Suggest main commands (e.g., typing "ca" suggests "card")
    for (DevCommand cmd in _commands) {
      if (cmd.name.startsWith(query)) matches.add(cmd.name);
    }

    // Suggest specific sub-arguments!
    matches.addAll(_mapMatches({"draw", "remove"}, "card", query));
    matches.addAll(_mapMatches({"add", "remove"}, "deck", query));
    matches.addAll(_mapMatches({"add", "remove"}, "pile", query));

    final sortTypes = DeckSortType.values.map((t) => t.name);
    matches.addAll(_mapMatches(sortTypes, "sortBy", query));

    final deckEvents = DeckEventEffect.values.map((e) => e.name);
    matches.addAll(_mapMatches(deckEvents, "deckEvent", query));

    return matches;
  }

  List<String> _mapMatches(
    Iterable<String> iterable,
    String prefix,
    String query,
  ) {
    return iterable
        .map((arg) => "$prefix $arg")
        .where((str) => str.startsWith(query))
        .toList();
  }
}
