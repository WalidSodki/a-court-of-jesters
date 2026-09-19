class_name Chest
extends Interactable
## A container that grants one item the first time it is opened.
## `item` and the sprite are configured by whoever places it (see DemoRoom).

@export var item: ItemData
var _opened := false


func _on_interact(_by: Node) -> void:
	if _opened:
		Dialogue.start([{"text": "The chest is empty."}])
		return
	_opened = true
	Inventory.add(item)
	AudioManager.play_sfx(&"pickup")
	_pop()
	Dialogue.start([{"text": "You found: %s." % item.display_name}])


## Quick squash-and-stretch so the pickup feels responsive.
func _pop() -> void:
	var s := get_node_or_null("Sprite") as Node2D
	if s == null:
		return
	var t := create_tween()
	t.tween_property(s, "scale", Vector2(1.25, 0.75), 0.07)
	t.tween_property(s, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
