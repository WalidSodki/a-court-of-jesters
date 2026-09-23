class_name Steward
extends Interactable
## The court steward. Placeable NPC whose one-time conversation includes the
## choice that sets `steward_impressed` and hands over the gift item.
##
## Prefers a data-authored `conversation` (branching/effects live in the .tres);
## the inline `gift_item` path below is the legacy fallback if none is assigned.

## Data-driven conversation graph. When set, drives the whole exchange.
@export var conversation: ConversationData
@export var gift_item: ItemData


func _on_interact(_by: Node) -> void:
	if conversation != null:
		Dialogue.start_conversation(conversation)
		return

	if GameState.get_flag("met_steward", false):
		var impressed := GameState.has_flag("steward_impressed")
		var line := "Make them laugh, jester." if impressed else "Do not embarrass this house, fool."
		Dialogue.start([{"speaker": "Steward", "text": line}])
		return

	GameState.set_flag("met_steward", true)
	var give_gift := func() -> void:
		if gift_item != null:
			Inventory.add(gift_item)
	Dialogue.start([
		{"speaker": "Steward", "text": "So. You are the new jester. The royal family expects a performance tonight."},
		{"speaker": "Steward", "text": "How will you present yourself to the court?", "choice": [
			{"text": "Bow deeply and promise a grand show.", "flag": "steward_impressed", "value": true},
			{"text": "Smirk and juggle an imaginary crown.", "flag": "steward_impressed", "value": false},
		]},
		{"call": give_gift},
		{"speaker": "Steward", "text": "Take this baton handle. Find your bells, make them one, and ready yourself at the stage."},
	])
