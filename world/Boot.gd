extends Node
## Entry point: hands off to the World manager, which loads the first room.
## Keeping room-loading in one place means every room (including the first)
## goes through the same fade/spawn path.

const FIRST_ROOM := "res://world/GreatHall.tscn"


func _ready() -> void:
	World.go_to(FIRST_ROOM)
