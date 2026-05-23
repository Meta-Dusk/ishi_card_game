# TODO

## Important

- [ ] Improve the UI/UX in-game, by reducing clutter and stuff
- [ ] Improve the opponents overview by making it scrollable and stuff
- [ ] Add a new view for "debuffs" in-game
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

- [ ] **Orb of Singularity**: Sacrifice 50 cards in hand to transform this relic into a card. Once played, all cards played after (up to 20) will become _assimilated_. These cards will make the **Orb** change its color, and if a player doesn't play anything, it will _punish_ them, by giving them all the cards _assimilated_ up until that point. Once the limit has been reached, it will simply vanish.
- [ ] **Rod of Discord**: Swap decks of all players to each other randomly, excluding the caster, unless they choose to swap with a specific player
- [ ] **Beretta 92FS**: Shoot a player. Shot players gets their turn skipped for 3 rounds
- [ ] **Pill of Convalescence**: Removes all current debuffs
- [ ] **Vessel of Avarice**: Open to obtain `Ishi Credits`
- [ ] **Book of Foresight**: Obtain the ability to view the cards of a _specific_ player, for the rest of the match
- [ ] **Book of Hindsight**: Become immune from being spied upon for the rest of the match
- [ ] **Pandora's Box**: Forcefully trigger a _random_ deck event
- [ ] **Mark 77**: Once used, it notifies everyone, and explodes after 1 round. Once it explodes, everyone's cards will be randomly covered in _napalm_, which will burn for 2 turns, rendering those cards `unusable`. After it finishes, the burnt cards will be discarded
- [ ] **Thermonuclear Warhead**: Once used, it notifies everyone, and explodes after 2 rounds. Once it explodes, everyone's cards will be immediately discarded, including the entire pile.
- [ ] **Flamethrower**: Once used on a player, 50% of their entire hand will become _scorched_. Cards with this effect will become `unusable` for 2 turns.

#### Cards

- [ ] (Wild) **TNT**: When played, removes 10 cards from the pile
- [ ] (Wild) **Claymore**: When played, explodes the next card played after it, essentially removing it from the played pile
- [ ] (Blue) **Ice Cube**: Starts at a random value between 5-9 , and _melts_ after each round, decreasing value by 1 each time. If it reaches 0, it will discard itself
- [ ] (Wild) **Wild Skip**: A _wild_ skip card.

### Events

#### Game

- [ ] A cards shop that opens once every 15 rounds
- [ ] Players who have more than 51 cards _implode_, halving their total cards in hand, and _stunning_ them for 2 turns

#### Deck

- [x] **Butterfly Effect**: The played card changes once per round

### Concepts

- `Ishi Credits` are only obtainable in-game, and are both usable in-game (tradeable in the cards shop), and in the _cosmetics shop_ found in the game's menus
- A tutorial in-game for first timers
- The _Cards Shop_ could be named **Ishi Store**, where players can buy and sell cards in, for `Ishi Credits`

## Bugs

- [ ] **Touchscreen Priority**: laptop issue, where interactivity only works for the touchscreen [_low priority_]
