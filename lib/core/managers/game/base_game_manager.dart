// abstract class BaseGameManager {
//   // --- CORE STATES ---
//   List<IshiCard> deck = [];
//   List<IshiCard> discardPile = [];

//   /// `playerHands`[`playerIndex`][`cardIndex`]
//   late List<List<IshiCard>> playerHands;

//   int playerCount;
//   int lastDeckTotalIndex = 0;

//   // --- ECONOMY STATES ---
//   late List<int> actionPoints;
//   late List<int> cardDraws;

//   /// `playerRelics`[`playerIndex`][`relicIndex`]
//   late List<List<Relic>> playerRelics;

//   final int startingHandSize;

//   // --- TURN STATES ---
//   int currentPlayer = 1;
//   int pendingDrawCount = 0;
//   CardColor? declaredColor;
//   int? winnerIndex;

//   /// The turn direction.
//   bool isClockwise = true;

//   /// Stacks if multiple skips are played.
//   int _playersToSkip = 0;

//   int turnDeadlineEpoch = 0;
//   static const int turnDurationSeconds = 60;
//   int get _getTurnDeadlineEpoch =>
//       DateTime.now().millisecondsSinceEpoch + (turnDurationSeconds * 1000);

//   int roundCount = 1;

//   // --- ACTION STATES ---
//   bool hasPlayedCard = false;
//   bool hasDrawnCard = false;
//   bool hasDeflected = false;

//   // --- NETWORK STATES ---

//   /// The Host is always 0. Clients will update this!
//   int localPlayerIndex = 0;

//   /// Stores the card counts for the UI.
//   List<int> opponentHandSizes = [];

//   // --- VISUAL STATES ---
//   DeckSortType handSortType = .unsorted;
//   bool isAutoSortEnabled = false;

//   // --- EVENTS ---
//   final _eventController = StreamController<GameManagerEvent>.broadcast();
//   Stream<GameManagerEvent> get events => _eventController.stream;

//   DeckEventEffect activeDeckEvent = .none;
//   int pendingEvolutions = 0;
//   bool manualTriggerDeckEvent = false;
//   final double chaosEffectChance = 0.25;

//   /// Gets called once the effect of the deck
//   /// event `butterflyEvent` gets triggered.
//   VoidCallback? onChaosTrigger;

//   /// Gets called once the effect of the deck
//   /// event `wildDoubleTrouble` gets triggered.
//   VoidCallback? onWildBuffTrigger;

//   /// Gets called once the effect of the deck
//   /// event `blueCardsFreeze` gets triggered.
//   VoidCallback? onFrozenTrigger;

//   /// Gets called once the effect of the deck
//   /// event `greenCardsEvolution` gets triggered.
//   VoidCallback? onEvolvedTrigger;

//   /// Gets called once a round ends.
//   VoidCallback? onRoundEnd;
// }
