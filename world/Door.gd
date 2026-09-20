class_name Door
extends Interactable
## Moves the player to another room via the World manager. Configure in-editor:
## drop this prefab into a room, set the target scene and the spawn point name.
##
## Optionally story-gated: set `require_flag` and the door only works (and only
## shows its prompt) while that flag equals `require_value` — used to keep the
## golden path linear (e.g. the passage door opens once `performance_done`).

@export_file("*.tscn") var target_scene: String
## Name of the Marker2D in the destination room to spawn at ("" = its default).
@export var spawn_id: StringName = &""
## If set, the door is enabled only while this flag equals `require_value`.
@export var require_flag: String = ""
@export var require_value := true


func _ready() -> void:
	if require_flag != "":
		GameState.flag_changed.connect(_on_flag_changed)
		_refresh_gate()


func _on_flag_changed(flag: String, _value: Variant) -> void:
	if flag == require_flag:
		_refresh_gate()


func _refresh_gate() -> void:
	enabled = bool(GameState.get_flag(require_flag)) == require_value


func _on_interact(_by: Node) -> void:
	if target_scene == "":
		return
	AudioManager.play_sfx(&"ui")
	World.go_to(target_scene, spawn_id)
