# TODO

## Important

- Add a new view for "debuffs" in-game.
- Add doubling effect for the other wild cards (only `+4` is currently implemented).
- Add ability to play other cards during attack from plus cards, if player has more than 1 AP.
- Modify the UI for the Windows version to show a lot more information, favoring the full screen mode.
- Try making the lobby not dissolve post-game (exiting the game just puts them into the lobby).
- Add relic usage animations that appears for all players (also show the total amount of relics a player has).

## Gameplay Ideas

### Game Modes

- **Versus AI**: A single player mode for battling against an AI (1v1).
- **Classic**: All default values for game config.
- **Blitz**: Fast-paced gameplay with 10 seconds turn timers.
- **Fourth Circle of Hell**: Game ends once a person obtains the **Orb of Singularity** card.
- **Legally Blind**: All cards in players' hands remain facing down (drawn cards are briefly shown) and the `flip hand` button will be disabled for the entire match.
- **Manhattan Project**: Whoever manages to detonate a nuke, wins the game.

### Cosmetic/Aesthetic Features

- Booster packs (cards unboxing, which may include card-specific skins, etc.).
- Achievements.
- Post-game review, where instead of a defeat/victory screen, players are also shown all their stats (of each player, and the game itself).
- Chest opening animation.

### New Cards

#### Relics

- **Orb of Singularity**: Sacrifice the first 50 cards in hand to transform this relic into a card. Once played, all cards played after (up to 20) will become _assimilated_. These cards will make the **Orb** change its color, and if a player doesn't play anything, it will _punish_ them, by giving them all the cards _assimilated_ up until that point. Once the limit has been reached, it will simply vanish.
- **Rod of Discord**: Swap decks of all players to each other randomly, excluding the caster, unless they choose to swap with a specific player. Consumes 1 AP.
- **Beretta 92FS**: Shoot a player. Shot players gets their turn skipped for 3 rounds.
- **Pill of Convalescence**: Removes all current debuffs.
- **Vessel of Avarice**: Open to obtain `Ishi Credits`. Doesn't consume AP.
- **Book of Foresight**: Obtain the ability to view the cards of a _specific_ player, for the rest of the match. Single-use.
- **Book of Hindsight**: Become immune from being spied upon for the rest of the match. Single-use.
- **Pandora's Box**: Forcefully trigger a _random_ deck event. Single-use.
- **Mark 77**: Once played, it immediately explodes. Once it explodes, everyone's cards will be randomly covered in _napalm_, which will burn for 2 turns, rendering those cards `unusable`. After it finishes, the burnt cards will be discarded. Requires a setup before becoming playable.
- **W53 (High-Yield Thermonuclear Warhead)**: Once played, it immediately explodes. Once it explodes, everyone's cards will be immediately discarded, including the entire pile. Also make this card require a setup, where a player must play a specific sequence of cards first before being able to use this, converting it into a playable card.
- **Flamethrower**: Once used on a player, 50% of their entire hand will become _scorched_. Cards with this effect will become `unusable` for 2 turns.
- **Atomic Splitter**: Once used on a card, the card _splits_ itself into two, the resulting cards' values are the sum of the original (only for number cards, and plus cards). As for non-number cards, they just get discarded.

#### Cards

- (Wild) **TNT**: When played, removes 10 cards from the pile.
- (Wild) **Claymore**: When played, explodes the next card played after it, essentially removing it from the played pile.
- (Blue) **Ice Cube**: Starts at a random value between 5-9 , and _melts_ after each round, decreasing value by 1 each time. If it reaches 0, it will discard itself.
- (Wild) **Wild Skip**: A _wild_ skip card.
- (Yellow) **Coins Bag**: Play to receive `Ishi Credits`.

##### Sequence Cards for the W53

They must be played in a specific order, or the **W53** will not become playable.

- (Wild) **Plutonium-239**: Sequence 1. On its own, it can _irradiate_ cards in your hand, which can randomize their contents.
- (Wild) **Highly Enriched Uranium**: Sequence 2. Doesn't do anything on its own.
- (Wild) **Tritium**: Sequence 3. Doesn't do anything on its own.
- (Wild) **Deuterium**: Sequence 4. Doesn't do anything on its own. Can be played without costing AP.

##### Sequence cards for the Mark 77

They must be played in a specific order, or the **Mark 77** will not become playable.

- (Wild) **Kerosene**: Sequence 1: On its own, playing it simply buffs any burning card (depending on their effect) after it.
- (Wild) **Polystyrene**: Doesn't do anything on its own.

### Events

#### Game

- A cards shop that opens once every 10 rounds (make the round interval shorter the more players there are).
- Players who have more than 51 cards _implode_, halving their total cards in hand, and _stunning_ them for 2 turns.

#### Deck

- **Black Friday**: All sold items in the **Ishi Store** are discounted at 50% off.

### Concepts

- `Ishi Credits` are only obtainable in-game, and are both usable in-game (tradeable in the cards shop), and in the _cosmetics shop_ found in the game's menus.
- A tutorial in-game for first timers.
- The _Cards Shop_ could be named **Ishi Store**, where players can buy and sell cards in, for `Ishi Credits`.
- Turn-based cooldowns/timers will adapt according to the total amount of players in the lobby.

## Bugs

- Red skips not skipping during a red card event.
- Natural deck events not triggering properly after manually triggering a deck event through commands.
