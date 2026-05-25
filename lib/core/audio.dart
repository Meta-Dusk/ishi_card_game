import 'dart:math';

class _Music {
  const _Music();

  static final Random _random = Random();

  final String gameLoop1 = "Patreon-Challenge-07.mp3";
  final String gameLoop2 = "Sketchbook 2024-09-12.mp3";
  final String gameLoop3 = "Sketchbook 2024-10-26.mp3";

  final String menuLoop1 = "Sketchbook_2024-12-04.mp3";
  final String menuLoop2 = "Sketchbook 2024-06-16.mp3";
  final String menuLoop3 = "VGMA Challenge 30.mp3";

  String get gameLoop {
    final List<String> gameLoops = [gameLoop1, gameLoop2, gameLoop3];
    return gameLoops[_random.nextInt(gameLoops.length)];
  }

  String get menuLoop {
    final List<String> menuLoops = [menuLoop1, menuLoop2, menuLoop3];
    return menuLoops[_random.nextInt(menuLoops.length)];
  }
}

class _SFX {
  const _SFX();

  final ui = const _UI();
  final cards = const _Cards();
}

class _Cards {
  const _Cards();

  /// Returns a random take card SFX from a pool of 2 unique sound effects.
  String get take => "cards/take_card_${Random().nextInt(2) + 1}.wav";

  /// Returns a random card mixing SFX from a pool of 8 unique sound effects.
  String get mix => "cards/card_mix_${Random().nextInt(8) + 1}.wav";

  final String place = "cards/place_card.wav";
}

class _UI {
  const _UI();

  final String itemSelect = "ui/item_select.wav";
}

class Audio {
  Audio._();

  static const music = _Music();
  static const sfx = _SFX();
}
