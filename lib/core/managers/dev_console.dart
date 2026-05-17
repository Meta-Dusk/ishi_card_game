import 'package:flutter/foundation.dart';
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

  void log(String message) {
    logs.add("> $message");
    onLogAdded?.call();
  }

  void dispose() {
    onLogAdded = null;
    onExit = null;
  }

  /// Registers all the dev commands.
  void initialize(GameManager manager, NetworkService net) {
    _commands.clear();

    _commands.add(
      DevCommand(
        name: "help",
        description: "Lists all available commands",
        onExecute: (_) {
          log("Available Commands:");
          for (DevCommand command in _commands) {
            log("  ${command.name} - ${command.description}");
          }
        },
      ),
    );

    _commands.add(
      DevCommand(
        name: "exit",
        description: "Closes the terminal",
        onExecute: (_) {
          if (onExit != null) {
            log("Closing terminal...");
            onExit!();
          } else {
            log("Failed to close terminal");
          }
        },
      ),
    );

    // CARD COMMAND
    _commands.add(
      DevCommand(
        name: "card",
        description: "Modifies your hand. Usage: card <draw|remove> [amount]",
        onExecute: (args) {
          if (args.isEmpty) {
            return log(
              "Error: Missing action. Usage: card <draw|remove> [amount]",
            );
          }
          String action = args[0].toLowerCase();
          int amount = args.length > 1 ? (int.tryParse(args[1]) ?? 1) : 1;

          if (action == "draw") {
            manager.forceDraw(manager.localPlayerIndex, count: amount);
            log("Drew $amount card${amount > 1 ? 's' : ''} to your hand.");
          } else if (action == "remove") {
            int removed = 0;
            for (int i = 0; i < amount; i++) {
              if (manager.playerHands[manager.localPlayerIndex].isNotEmpty) {
                manager.playerHands[manager.localPlayerIndex].removeLast();
                removed++;
              }
            }
            log(
              "Removed $removed card${amount > 1 ? 's' : ''} from your hand.",
            );
          } else {
            log("Error: Unknown action '$action'. Use 'draw' or 'remove'.");
          }
        },
      ),
    );

    // DECK COMMAND (Modifies the Play Deck / Discard Pile)
    _commands.add(
      DevCommand(
        name: "deck",
        description:
            "Modifies the play deck. Usage: deck <add|remove> [amount]",
        onExecute: (args) {
          if (args.isEmpty) {
            return log(
              "Error: Missing action. Usage: deck <add|remove> [amount]",
            );
          }
          String action = args[0].toLowerCase();
          int amount = args.length > 1 ? (int.tryParse(args[1]) ?? 1) : 1;

          if (action == "add") {
            int added = 0;
            for (int i = 0; i < amount; i++) {
              if (manager.deck.isNotEmpty) {
                // Safely "add" to play deck by pulling from the draw pile
                manager.discardPile.add(manager.deck.removeLast());
                added++;
              }
            }
            log(
              "Added $added card${added > 1 ? 's' : ''} to play deck "
              "(pulled from draw pile).",
            );
          } else if (action == "remove") {
            int removed = 0;
            for (int i = 0; i < amount; i++) {
              if (manager.discardPile.isNotEmpty) {
                manager.discardPile.removeLast();
                removed++;
              }
            }
            log(
              "Removed $removed card${removed > 1 ? 's' : ''} "
              "from the play deck.",
            );
          } else {
            log("Error: Unknown action '$action'. Use 'add' or 'remove'.");
          }
        },
      ),
    );

    // PILE COMMAND (Modifies the Draw Pile / Remaining Cards)
    _commands.add(
      DevCommand(
        name: "pile",
        description:
            "Modifies the draw pile. Usage: pile <add|remove> [amount]",
        onExecute: (args) {
          if (args.isEmpty) {
            return log(
              "Error: Missing action. Usage: pile <add|remove> [amount]",
            );
          }
          String action = args[0].toLowerCase();
          int amount = args.length > 1 ? (int.tryParse(args[1]) ?? 1) : 1;

          if (action == "add") {
            int added = 0;
            for (int i = 0; i < amount; i++) {
              if (manager.discardPile.isNotEmpty) {
                // Safely "add" to draw pile by pulling from the play deck
                manager.deck.add(manager.discardPile.removeLast());
                added++;
              }
            }
            log(
              "Added $added card${added > 1 ? 's' : ''} to draw pile "
              "(pulled from play deck).",
            );
          } else if (action == "remove") {
            int removed = 0;
            for (int i = 0; i < amount; i++) {
              if (manager.deck.isNotEmpty) {
                manager.deck.removeLast();
                removed++;
              }
            }
            log(
              "Removed $removed card${removed > 1 ? 's' : ''} from the draw pile.",
            );
          } else {
            log("Error: Unknown action '$action'. Use 'add' or 'remove'.");
          }
        },
      ),
    );

    // SORTBY COMMAND
    _commands.add(
      DevCommand(
        name: "sortby",
        description:
            "Sorts your hand. Usage: sortby <color|type|value|unsorted>",
        onExecute: (args) {
          if (args.isEmpty) {
            return log(
              "Error: Missing sort type. Usage: sortby <color|type|value|unsorted>",
            );
          }
          String type = args[0].toLowerCase();

          DeckSortType? sortType;
          switch (type) {
            case "color":
              sortType = .byColor;
              break;
            case "type":
              sortType = .byType;
              break;
            case "value":
              sortType = .byValue;
              break;
            case "unsorted":
              sortType = .unsorted;
              break;
            default:
              return log("Error: Unknown sort type '$type'.");
          }

          // Apply the sort directly to the manager
          manager.handSortType = sortType;
          manager.sortHand(manager.localPlayerIndex, sortType);
          log("Hand sorted by $type.");
        },
      ),
    );

    _commands.add(
      DevCommand(
        name: "kick",
        description: "Kicks a player. Usage: kick [index]",
        onExecute: (args) {
          if (!net.isHost) return log("Error: Only the host can kick.");
          if (args.isEmpty) {
            return log("Error: Missing index. Usage: kick [index]");
          }
          int index = int.tryParse(args[0]) ?? 0;

          net.kickPlayer(index, reason: "Kicked via dev console.");
          log("Attempted to kick player at index $index.");
        },
      ),
    );

    _commands.add(
      DevCommand(
        name: "cls",
        description: "Clears the console log",
        onExecute: (_) {
          logs.clear();
          onLogAdded?.call();
        },
      ),
    );

    _commands.add(
      DevCommand(
        name: "endgame",
        description: "Ends the game on your terms",
        onExecute: (_) {
          log("Ending game...");
          manager.winnerIndex = 0;
          manager.addEvent(.gameOver);
        },
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
