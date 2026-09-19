extends Node
## The single source of truth for control mode and story flags.
##
## Every system that gates input reads `mode` here rather than poking flags on
## the player. Story choices are recorded as flags so consequences can persist
## and be queried later. Serializable via to_dict/from_dict for future saves.

signal mode_changed(new_mode: int, old_mode: int)
signal flag_changed(flag: String, value: Variant)

## The control mode. Player input is only active in EXPLORING.
enum Mode { EXPLORING, DIALOGUE, MENU, CUTSCENE, MINIGAME }

# Modes are a stack so systems can nest (e.g. a cutscene that opens dialogue)
# and cleanly restore the previous mode when they finish.
var _mode_stack: Array[int] = [Mode.EXPLORING]
var story_flags: Dictionary = {}

var mode: int:
	get:
		return _mode_stack.back()


func push_mode(new_mode: int) -> void:
	var old := mode
	_mode_stack.push_back(new_mode)
	mode_changed.emit(new_mode, old)


func pop_mode() -> void:
	if _mode_stack.size() <= 1:
		return
	var old: int = _mode_stack.pop_back()
	mode_changed.emit(mode, old)


func is_exploring() -> bool:
	return mode == Mode.EXPLORING


func mode_name() -> String:
	return Mode.keys()[mode]


func set_flag(flag: String, value: Variant = true) -> void:
	story_flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: String, default: Variant = false) -> Variant:
	return story_flags.get(flag, default)


func has_flag(flag: String) -> bool:
	return bool(story_flags.get(flag, false))


func to_dict() -> Dictionary:
	return {"flags": story_flags.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	story_flags = (data.get("flags", {}) as Dictionary).duplicate(true)
