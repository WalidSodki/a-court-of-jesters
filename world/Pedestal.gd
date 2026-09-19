class_name Pedestal
extends Interactable
## The stage prop stand. Accepts a required item (the combined marotte),
## sets a story flag, and gives a satisfying flourish. This is the seam the
## Milestone 2 court-performance minigame will hook onto.

@export var required_item: ItemData
@export var flag: String = "stage_ready"
var done := false

signal completed


func _on_interact(_by: Node) -> void:
	if done:
		Dialogue.start([{"text": "The stage is set. The court is waiting."}])
		return

	# "Use item on world object": prefer the explicitly held item, but accept
	# simply carrying it so the puzzle is forgiving.
	var have := Inventory.held_item == required_item or Inventory.has(required_item)
	if not have:
		Dialogue.start([{"text": "The stage needs a proper prop. Perhaps something can be made from what you carry."}])
		return

	done = true
	if Inventory.has(required_item):
		Inventory.remove(required_item)
	GameState.set_flag(flag, true)
	AudioManager.play_sfx(&"success")
	_flourish()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("shake_camera"):
		player.shake_camera(3.0, 0.35)
	completed.emit()

	var impressed := GameState.has_flag("steward_impressed")
	var line := "You set the %s upon the stage. Lanterns flare to life and the court leans in, delighted." % required_item.display_name
	if not impressed:
		line = "You set the %s upon the stage. The court quiets — the steward watches, unamused." % required_item.display_name
	Dialogue.start([{"text": line}])


func _flourish() -> void:
	var s := get_node_or_null("Sprite") as Node2D
	if s == null:
		return
	var t := create_tween()
	t.tween_property(s, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "scale", Vector2.ONE, 0.15)
