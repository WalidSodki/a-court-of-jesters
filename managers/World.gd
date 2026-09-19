extends Node
## Owns room switching: fade out, swap the room scene, fade in. Rooms are
## instanced under the tree root (autoloads like GameState/Inventory persist),
## so each room is a self-contained scene the player can also open directly.

var current_room: Node
var current_path := ""
var pending_spawn: StringName = &""
var _busy := false


func go_to(scene_path: String, spawn_id: StringName = &"") -> void:
	if _busy:
		return
	_busy = true
	if is_instance_valid(current_room):
		await Transitions.fade_out(0.35)
		current_room.queue_free()
		await current_room.tree_exited

	pending_spawn = spawn_id
	current_path = scene_path
	var room: Node = load(scene_path).instantiate()
	# Deferred: the root may still be setting up children (e.g. first load from
	# Boot._ready), which forbids a direct add_child.
	get_tree().root.add_child.call_deferred(room)
	current_room = room

	await get_tree().process_frame
	await get_tree().process_frame
	Transitions.fade_in(0.4)
	_busy = false


func reload() -> void:
	if current_path != "":
		go_to(current_path)


## A room reads this once when spawning the player (returns "" if unset).
func consume_spawn() -> StringName:
	var s := pending_spawn
	pending_spawn = &""
	return s
