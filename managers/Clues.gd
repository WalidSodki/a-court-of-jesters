extends Node
## The player's discovered clues. Autoloaded so it persists across scenes and
## folds into the save system alongside GameState + Inventory. Modeled on
## Inventory: clues are data (ClueData), discovered as the player investigates,
## and queryable so dialogue/puzzles can react to what the player knows.

signal changed
signal clue_discovered(clue: ClueData)

var discovered: Array[ClueData] = []


func discover(clue: ClueData) -> void:
	if clue == null or has_clue(clue):
		return
	discovered.append(clue)
	AudioManager.play_sfx(&"clue")
	clue_discovered.emit(clue)
	changed.emit()


func has_clue(clue: ClueData) -> bool:
	return discovered.has(clue)


func has(id: StringName) -> bool:
	for c in discovered:
		if c.id == id:
			return true
	return false


func to_dict() -> Dictionary:
	var ids: Array[String] = []
	for c in discovered:
		ids.append(String(c.id))
	return {"clues": ids}


## Restores from ids. Needs a lookup from id -> ClueData; the save system passes
## one in so Clues stays agnostic about where clue resources live.
func from_dict(data: Dictionary, resolve: Callable) -> void:
	discovered.clear()
	for id in data.get("clues", []):
		var clue := resolve.call(StringName(id)) as ClueData
		if clue != null:
			discovered.append(clue)
	changed.emit()
