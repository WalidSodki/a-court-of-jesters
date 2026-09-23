class_name DialogueEffect
extends Resource
## Data-described side effects, applied when a node is shown or a choice picked.
## Consequences route through GameState / Inventory / Clues so they persist and
## are queryable later — never scattered as local booleans.

## Flags to set: {flag_name: value}. Values may be bool / int / String.
@export var set_flags: Dictionary = {}
## Items to grant to the inventory.
@export var grant_items: Array[ItemData] = []
## Clues to discover (add to the journal).
@export var discover_clues: Array[ClueData] = []


func apply() -> void:
	for key in set_flags:
		GameState.set_flag(String(key), set_flags[key])
	for item in grant_items:
		if item != null:
			Inventory.add(item)
	for clue in discover_clues:
		if clue != null:
			Clues.discover(clue)
