import 'package:ishi/core/dev/dev_console.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/models/deck_event.dart';
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
      onExecute: (_, _) {
        console.log("Available Commands:");
        for (DevCommand command in allCommandsRef) {
          final usage = command.usage != null ? "Usage: ${command.usage}" : "";
          console.log("  ${command.name} - ${command.description} $usage");
        }
      },
    ),
    DevCommand(
      name: "exit",
      description: "Closes the terminal",
      onExecute: (_, _) {
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
      description: "Modifies your hand.",
      usage: "card <draw|remove> [amount]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing amount. Usage: $usage");
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
      description: "Modifies the play deck.",
      usage: "deck <add|remove> [amount]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing amount. Usage: $usage");
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
      description: "Modifies the draw pile.",
      usage: "pile <add|remove> [amount]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing amount. Usage: $usage");
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
      name: "sortBy",
      description: "Sorts your hand.",
      usage: "sortBy <color|type|value|unsorted>",
      onExecute: (args, usage) {
        if (args.isEmpty) {
          return console.log("Error: Missing sort type. Usage: $usage");
        }
        String type = args[0].toLowerCase();
        final finalSortType = DeckSortType.values.asNameMap()[type];

        if (finalSortType != null) {
          manager.handSortType = finalSortType;
          manager.sortHand(manager.localPlayerIndex, finalSortType);
          console.log("Hand sorted by $type.");
        } else {
          return console.log("Error: Unknown sort type '$type'.");
        }
      },
    ),
    DevCommand(
      name: "kick",
      description: "Kicks a player.",
      usage: "kick [index]",
      onExecute: (args, usage) {
        if (!net.isHost) return console.log("Error: Only the host can kick.");
        if (args.isEmpty) {
          return console.log("Error: Missing index. Usage: $usage");
        }
        int index = int.tryParse(args[0]) ?? 0;
        net.kickPlayer(index, reason: "Kicked via dev console.");
        console.log("Attempted to kick player at index $index.");
      },
    ),
    DevCommand(
      name: "cls",
      description: "Clears the console log",
      onExecute: (_, _) {
        console.logs.clear();
        console.onLogAdded?.call();
      },
    ),
    DevCommand(
      name: "win",
      description: "Makes a specific player the winner.",
      usage: "win [index]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing index. Usage: $usage");
        }
        int index = int.tryParse(args[0]) ?? 0;
        console.log("Ending game for player $index...");
        manager.winnerIndex = index;
        manager.addEvent(.gameOver);
        console.onStateForceSynced?.call();
      },
    ),
    DevCommand(
      name: "setTime",
      description: "Sets the current running turn timer to a value.",
      usage: "setTime [seconds]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing seconds. Usage: $usage");
        }
        int value = int.tryParse(args[0]) ?? 0;
        console.log("Setting current running turn timer to: $value");
        manager.turnDeadlineEpoch = value;
      },
    ),
    DevCommand(
      name: "deckEvent",
      description: "Trigger a deck event.",
      usage: "deckevent [type]",
      onExecute: (args, usage) {
        if (!net.isHost) {
          return console.log("Error: Only the host can modify the game state!");
        }
        if (args.isEmpty) {
          return console.log("Error: Missing type. Usage: $usage");
        }
        String type = args[0];
        final selectedEvent = DeckEventEffect.values.asNameMap()[type];

        if (selectedEvent != null) {
          manager.activeDeckEvent = selectedEvent;
          console.log("Triggered deck event: ${selectedEvent.name}");
          manager.addEvent(.deckEventTriggered);
          console.onStateForceSynced?.call();
        } else {
          console.log("Error: Unknown deck event '$type'");
        }
      },
    ),
  ];
}
