# TODO

## Important

- [ ] Improve the UI/UX in-game, by reducing clutter and stuff
- [ ] Improve the opponents overview by making it scrollable and stuff
- [ ] Add a new view for "debuffs" in-game
- [ ] Change the nature deck event to instead inflict `evolution`, which makes all green cards played, _evolve_ the next not-green card, which can either increment their value (if below 9), cycle to the next color (if 9, or skip), or just upgrade to a +4, if it's already a +2 of any color
- [ ] Temporarily remove the local multiplayer option, and just make it be enabled through the dev console with `showLocalMultiplayer <true|false>`
- [ ] Nerf the `Staff of Polymorphism` to require AP to polymorph a card, and also restrict choices to be unique cards only, which saves the already chosen cards to the entire match, per player

## Gameplay Ideas

### Game Modes

- [ ] **Versus AI**: A single player mode for battling against an AI (1v1)
- [ ] **Classic**: All default values for game config
- [ ] **Blitz**: Fast-paced gameplay with 10 seconds turn timers
- [ ] **Fourth Circle of Hell**: Game ends once a person obtains the **Orb of Singularity** relic

### Cosmetic/Aesthetic Features

- [ ] Booster packs (cards unboxing, which may include card-specific skins, etc.)
- [ ] Achievements
- [ ] Post-game review, where instead of a defeat/victory screen, players are also shown all their stats (of each player, and the game itself)
- [ ] Chest opening animation

### New Cards

#### Relics

- [ ] (Relic) **Orb of Singularity**: Sacrifice 50 cards in hand to make 1 special card
- [ ] (Relic) **Rod of Discord**: Swap decks of all players to each other randomly, excluding the caster, unless they choose to swap with a specific player
- [ ] (Relic) **Beretta 92FS**: Shoot a player. Shot players gets their turn skipped for 3 rounds
- [ ] (Relic) **Pill of Convalescence**: Removes all current debuffs
- [ ] (Relic) **Vessel of Avarice**: Open to obtain `Ishi Credits`
- [ ] (Relic) **Book of Foresight**: Permanently be able to view the cards of a player
- [ ] (Relic) **Pandora's Box**: Forcefully trigger a random deck event
- [ ] (Relic) **Mark 77**: Once used, it notifies everyone, and explodes after 1 round. Once it explodes, everyone's cards will be randomly covered in _napalm_, which will burn for 2 turns. After it finishes, the burnt card will be discarded
- [ ] (Relic) **Thermonuclear Warhead**: Once used, it notified everyone, and explodes after 2 rounds. Once it explodes, everyone's cards will be immediately discarded, including the entire pile.
- [ ] (Relic) **Flamethrower**: Once used on a player, 50% of their entire hand will become _scorched_. Cards with this effect will become `unusable` for 2 turns.

#### Cards

- [ ] (Wild Card) **TNT**: When played, removes 10 cards from the pile
- [ ] (Wild Card) **Claymore**: When played, explodes the next card played after it, essentially removing it from the played pile
- [ ] (Blue Card) **Ice Cube**: Starts at a value of 9, and _melts_ after each round, decreasing value by 1 each time. If it reaches 0, it will discard itself

### Events

#### Game

- [ ] (Game Event) A cards shop that opens once every 15 rounds
- [ ] (Game Event) Players who have more than 51 cards _implode_, halving their total cards in hand, and _stunning_ them for 2 turns

#### Deck

- [ ] (Deck Event) **Butterfly Effect**: The played card changes once per round

### Concepts

- `Ishi Credits` are only obtainable in-game, and are both usable in-game (tradeable in the cards shop), and in the _cosmetics shop_ found in the game's menus
- A tutorial in-game for first timers
- The _Cards Shop_ could be named **Ishi Store**, where players can buy and sell cards in, for `Ishi Credits`

## Bugs

- [ ] **Touchscreen Priority**: laptop issue, where interactivity only works for the touchscreen [_low prio_]
