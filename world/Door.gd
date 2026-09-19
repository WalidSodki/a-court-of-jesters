class_name Door
extends Interactable
## Moves the player to another room via the World manager. Configure in-editor:
## drop this prefab into a room, set the target scene and the spawn point name.

@export_file("*.tscn") var target_scene: String
## Name of the Marker2D in the destination room to spawn at ("" = its default).
@export var spawn_id: StringName = &""


func _on_interact(_by: Node) -> void:
	if target_scene == "":
		return
	AudioManager.play_sfx(&"ui")
	World.go_to(target_scene, spawn_id)
