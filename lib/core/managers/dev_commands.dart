import 'package:ishi/core/managers/dev_console.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';

class DevCommandRegistry {
  static List<DevCommand> buildCommands({
    required GameManager manager,
    required NetworkService net,
    required DevConsole console,
    required List<DevCommand> allCommandsRef,
  }) => [
    DevCommand(
      name: "help",
      description: "Lists all available commands",
      onExecute: (_) {
        console.log("Available Commands:");
        for (DevCommand command in allCommandsRef) {
          console.log("  ${command.name} - ${command.description}");
        }
      },
    ),
    DevCommand(
      name: "exit",
      description: "Closes the terminal",
      onExecute: (_) {
        if (console.onExit != null) {
          console.log("Closing terminal...");
          console.onExit!();
        } else {
          console.log("Failed to close terminal");
        }
      },
    ),

    // CARD COMMAND
    DevCommand(
      name: "card",
      description: "Modifies your hand. Usage: card <draw|remove> [amount]",
      onExecute: (args) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log(
            "Error: Missing action. Usage: card <draw|remove> [amount]",
          );
        }
        String action = args[0].toLowerCase();
        int amount = args.length > 1 ? (int.tryParse(args[1]) ?? 1) : 1;

        if (action == "draw") {
          manager.forceDraw(manager.localPlayerIndex, count: amount);
          console.log(
            "Drew $amount card${amount > 1 ? 's' : ''} to your hand.",
          );
          console.onStateForceSynced?.call();
        } else if (action == "remove") {
          int removed = 0;
          for (int i = 0; i < amount; i++) {
            if (manager.playerHands[manager.localPlayerIndex].isNotEmpty) {
              manager.playerHands[manager.localPlayerIndex].removeLast();
              removed++;
            }
          }
          console.log(
            "Removed $removed card${amount > 1 ? 's' : ''} from your hand.",
          );
          console.onStateForceSynced?.call();
        } else {
          console.log(
            "Error: Unknown action '$action'. Use 'draw' or 'remove'.",
          );
        }
      },
    ),

    // DECK COMMAND (Modifies the Play Deck / Discard Pile)
    DevCommand(
      name: "deck",
      description: "Modifies the play deck. Usage: deck <add|remove> [amount]",
      onExecute: (args) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log(
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
          console.log(
            "Added $added card${added > 1 ? 's' : ''} to play deck "
            "(pulled from draw pile).",
          );
          console.onStateForceSynced?.call();
        } else if (action == "remove") {
          int removed = 0;
          for (int i = 0; i < amount; i++) {
            if (manager.discardPile.isNotEmpty) {
              manager.discardPile.removeLast();
              removed++;
            }
          }
          console.log(
            "Removed $removed card${removed > 1 ? 's' : ''} "
            "from the play deck.",
          );
          console.onStateForceSynced?.call();
        } else {
          console.log(
            "Error: Unknown action '$action'. Use 'add' or 'remove'.",
          );
        }
      },
    ),

    // PILE COMMAND (Modifies the Draw Pile / Remaining Cards)
    DevCommand(
      name: "pile",
      description: "Modifies the draw pile. Usage: pile <add|remove> [amount]",
      onExecute: (args) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log(
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
          console.log(
            "Added $added card${added > 1 ? 's' : ''} to draw pile "
            "(pulled from play deck).",
          );
          console.onStateForceSynced?.call();
        } else if (action == "remove") {
          int removed = 0;
          for (int i = 0; i < amount; i++) {
            if (manager.deck.isNotEmpty) {
              manager.deck.removeLast();
              removed++;
            }
          }
          console.log(
            "Removed $removed card${removed > 1 ? 's' : ''} from the draw pile.",
          );
          console.onStateForceSynced?.call();
        } else {
          console.log(
            "Error: Unknown action '$action'. Use 'add' or 'remove'.",
          );
        }
      },
    ),

    // SORTBY COMMAND
    DevCommand(
      name: "sortby",
      description: "Sorts your hand. Usage: sortby <color|type|value|unsorted>",
      onExecute: (args) {
        if (args.isEmpty) {
          return console.log(
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
            return console.log("Error: Unknown sort type '$type'.");
        }

        // Apply the sort directly to the manager
        manager.handSortType = sortType;
        manager.sortHand(manager.localPlayerIndex, sortType);
        console.log("Hand sorted by $type.");
      },
    ),
    DevCommand(
      name: "kick",
      description: "Kicks a player. Usage: kick [index]",
      onExecute: (args) {
        if (!net.isHost) return console.log("Error: Only the host can kick.");
        if (args.isEmpty) {
          return console.log("Error: Missing index. Usage: kick [index]");
        }
        int index = int.tryParse(args[0]) ?? 0;
        net.kickPlayer(index, reason: "Kicked via dev console.");
        console.log("Attempted to kick player at index $index.");
      },
    ),
    DevCommand(
      name: "cls",
      description: "Clears the console log",
      onExecute: (_) {
        console.logs.clear();
        console.onLogAdded?.call();
      },
    ),
    DevCommand(
      name: "win",
      description: "Makes a specific player the winner. Usage: win [index]",
      onExecute: (args) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing index. Usage: win [index]");
        }
        int index = int.tryParse(args[0]) ?? 0;
        console.log("Ending game for player $index...");
        manager.winnerIndex = index;
        manager.addEvent(.gameOver);
        console.onStateForceSynced?.call();
      },
    ),
  ];
}
