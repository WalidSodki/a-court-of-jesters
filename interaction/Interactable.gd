class_name Interactable
extends Area2D
## Anything the player can interact with: NPCs, chests, doors, puzzle objects.
## The player always interacts the same way; subclasses (or a connected signal)
## decide what actually happens.

@export var prompt: String = "Examine"
@export var enabled: bool = true

signal interacted(by: Node)


func interact(by: Node) -> void:
	if not enabled:
		return
	interacted.emit(by)
	_on_interact(by)


## Override in subclasses to define behavior.
func _on_interact(_by: Node) -> void:
	pass


func get_prompt() -> String:
	return prompt
