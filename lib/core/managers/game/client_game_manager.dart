import 'base_game_manager.dart';
import 'package:ishi/core/network/network_messages.dart';

class ClientGameManager extends BaseGameManager {
  final Function(NetMessage) sendNetworkMessage;

  ClientGameManager(this.sendNetworkMessage);

  @override
  void playCard(String cardId) {
    final cardToPlay = playerHands[localPlayerIndex].firstWhere(
      (c) => c.id == cardId,
      orElse: () => throw Exception('Card not found in hand!'),
    );

    if (!canPlay(cardToPlay, localPlayerIndex).canPlay) {
      return;
    }

    sendNetworkMessage(
      PlayIntentMessage(
        action: .playCard,
        playerIndex: localPlayerIndex,
        cardId: cardId,
      ),
    );
  }

  @override
  void drawCard() {
    if (cardDraws[localPlayerIndex] <= 0) return;

    sendNetworkMessage(
      PlayIntentMessage(action: .drawCard, playerIndex: localPlayerIndex),
    );
  }

  @override
  void endTurn() {
    sendNetworkMessage(
      PlayIntentMessage(action: .endTurn, playerIndex: localPlayerIndex),
    );
  }

  @override
  void takePenalty() {
    sendNetworkMessage(
      PlayIntentMessage(action: .takePenalty, playerIndex: localPlayerIndex),
    );
  }
}
