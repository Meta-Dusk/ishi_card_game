part of 'relic.dart';

// Staff of Polymorphism
Future<IshiCard?> _onPolymorphDialog({
  required BuildContext context,
  required GameManager manager,
  required Relic relic,
}) async {
  final useCost = relic.useCost!;
  final errorMessage =
      "Insufficient Action Points! Polymorph costs $useCost AP.";

  if (manager.actionPoints[manager.localPlayerIndex] < useCost) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 1),
      ),
    );
    debugPrint(errorMessage);
    return null;
  }

  final card = await showDialog<IshiCard>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PolymorphDialog(usedCardIds: relic.memory),
  );
  debugPrint("Chosen card: $card");
  return card;
}

Future<IshiCard?> _onPolymorph({
  required GameManager manager,
  required GameScreenState gameState,
  required List<IshiCard> targets,
  required IshiCard chosenTemplate,
  required int playerIndex,
}) async {
  final localUIindex = gameState.localUIIndex;
  int lastModifiedIndex = 0;

  for (IshiCard target in targets) {
    final currentPlayer = manager.playerHands[playerIndex];
    int index = currentPlayer.indexOf(target);
    if (index == -1) continue;
    lastModifiedIndex = index;
    IshiCard polymorphedCard = IshiCard(
      id: target.id,
      color: chosenTemplate.color,
      type: chosenTemplate.type,
      number: chosenTemplate.number,
    );
    currentPlayer[index] = polymorphedCard;
  }
  // Force the AnimatedList to rebuild so the new colors instantly show
  gameState.listKeys[localUIindex] = GlobalKey<AnimatedListState>();

  if (playerIndex == manager.localPlayerIndex) {
    final controller = gameState.scrollControllers[localUIindex];
    if (controller != null && controller.hasClients) {
      final targetOffset = lastModifiedIndex * itemWidth;
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }
  return null;
}

// The Obliterator
Future<IshiCard?> _onObliterate({
  required GameManager manager,
  required GameScreenState gameState,
  required List<IshiCard> targets,
}) async {
  final playerIndex = manager.localPlayerIndex;

  for (IshiCard target in targets) {
    int index = manager.playerHands[playerIndex].indexOf(target);
    if (index == -1) continue;
    // Remove from logic
    manager.playerHands[playerIndex].removeAt(index);

    if (playerIndex == manager.localPlayerIndex) {
      gameState.removeCard(index, target);
    }
  }
  return null;
}
