class_name ExamineSpot
extends Interactable
## Generic examinable prop: shows lines of dialogue, optionally sets a flag,
## shakes the camera, and plays a sound. Used for the ghost, notes, signs, etc.
## Fully configured in the inspector.

@export var speaker: String = ""
@export_multiline var lines: PackedStringArray
@export var set_story_flag: String = ""
@export var camera_shake: float = 0.0
@export var sfx: StringName = &""


func _on_interact(_by: Node) -> void:
	if camera_shake > 0.0:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("shake_camera"):
			player.shake_camera(camera_shake, 0.4)
	if sfx != &"":
		AudioManager.play_sfx(sfx)
	if set_story_flag != "":
		GameState.set_flag(set_story_flag, true)

	var seq: Array = []
	for line in lines:
		seq.append({"speaker": speaker, "text": line})
	if seq.is_empty():
		seq = [{"text": "Nothing of note."}]
	Dialogue.start(seq)
