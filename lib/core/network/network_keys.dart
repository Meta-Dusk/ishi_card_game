part of 'network_messages.dart';

class _NetKey {
  // --- MESSAGE TYPES ---
  static const String type = 'type';

  // --- LOBBY PAYLOADS ---
  static const String timestamp = 'timestamp';
  static const String payload = 'payload';

  static const String playersList = 'playersList';
  static const String playerName = 'playerName';
  static const String pingMs = 'pingMs';

  static const String totalPlayers = 'totalPlayers';
  static const String avatarColorName = 'avatarColorName';

  // --- GAME STATE PAYLOADS ---
  static const String playerIndex = 'playerIndex';
  static const String declaredColor = 'declaredColor';
  static const String effect = 'effect';

  // --- INTENT ACTIONS ---
  static const String action = 'action';

  // --- ACTION PAYLOADS ---
  static const String cardId = 'cardId';
  static const String relicId = 'relicId';
  static const String targetCardIds = 'targetCardIds';
  static const String polymorphTemplate = 'polymorphTemplate';
}
