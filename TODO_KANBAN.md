---

kanban-plugin: board

---

## Pending (10)

- [ ] #bug #rework
	# Cards Display
	Try fix the minor visual hiccup seen in the player's POV of their hand when cards are removed.


## In Progress (5)

- [ ] #documentation #rework
	# Game Manager
	Update the game manager's architecture, by splitting its logic specifically for the host, and client respectively (split into two files). @{2026-06-09}
- [ ] #bug #mobile 
	# Mobile Bug
	Draw card pile not interactable somehow. @{2026-06-08}
- [ ] #rework #mobile #feature
	# Mobile UI
	Make the buttons a lot more intuitive and maybe just add a button for drawing cards, for accessibility. @{2026-06-08}


## Done

- [ ] #optimization #rework 
	# Optimizations
	Extract large `Widget` methods into their own class.
	@{2026-06-08}
- [ ] #rework #optimization #documentation 
	# Networking
	Update the networking code (coding style, type safety, data structures, legibility). @{2026-06-09}


***

## Archive

- [ ] #github #documentation
	# Deployment
	Deploy a GitHub webpage for viewing a simpler version of the game's roadmap.
	@{2026-06-07} | 2026-06-07 14:56

%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false],"full-list-lane-width":true,"show-relative-date":true,"archive-with-date":true,"append-archive-date":true,"archive-date-separator":"|","move-tags":true,"tag-sort":[{"tag":"#bug"},{"tag":"#feature"},{"tag":"#documentation"},{"tag":"#optional"}],"tag-colors":[{"tagKey":"#bug","color":"rgba(255, 120, 120, 1)","backgroundColor":"rgba(101, 0, 0, 1)"},{"tagKey":"#feature","color":"rgba(116, 172, 255, 1)","backgroundColor":"rgba(0, 85, 255, 0.65)"},{"tagKey":"#mobile","color":"rgba(221, 115, 235, 1)","backgroundColor":"rgba(48, 0, 115, 0.88)"},{"tagKey":"#optional","color":"rgba(128, 128, 128, 1)","backgroundColor":"rgba(58, 58, 58, 0.94)"},{"tagKey":"#documentation","color":"rgba(74, 125, 255, 1)","backgroundColor":"rgba(0, 4, 65, 1)"},{"tagKey":"#github","color":"rgba(0, 0, 0, 1)","backgroundColor":"rgba(255, 255, 255, 1)"}],"show-checkboxes":false,"move-dates":true,"date-colors":[{"distance":1,"unit":"days","direction":"after","backgroundColor":"rgba(21, 214, 86, 0.42)","color":"rgba(255, 255, 255, 1)","isToday":true},{"distance":1,"unit":"days","direction":"after","isAfter":true}]}
```
%%