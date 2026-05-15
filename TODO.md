# TODO

- [x] Implement LAN multiplayer
- [x] Add online multiplayer with **Supabase**
- [x] Add an official main menu
- [ ] Add more relics
- [ ] Add more special roguelike cards
- [ ] Add proper game loop (`new game => win game => end game`)
- [ ] Add leave, disband buttons
- [ ] Add message popups for players joining/leaving
- [x] Add better indicators for player turn (like different bgs, some effects, and show player name)
- [x] Fix avatar colors not displaying correctly
- [ ] Add sound effects and music
- [ ] Make popup dialogs minimizable (such as color selection)
- [ ] Update clients' game UI (move the AP and CD display closer to the hand)

## Gameplay Ideas

- [ ] _God Mode_ cards (like a special card that turns all cards in your hand into _something else_)
- [ ] _Rod of Discord_ (change position in turn order)
- [ ] Booster packs (cards unboxing, which may include card-specific skins, etc.)
- [ ] Achievements

## Bugs

- [ ] Touchscreen priority (laptop issue, where interactivity only works for the touchscreen) [_low prio_]
- [ ] (_Online Mode_) Occasional ghost player (add kick button, and kick `null players`)
- [ ] Game Over screen only visible to non-host clients
- [ ] Fix card sorting only sorting non-hosts' hands for new cards being added
- [ ] Fix the minicards count not reflecting the actual hand count for the opponents, in the host
