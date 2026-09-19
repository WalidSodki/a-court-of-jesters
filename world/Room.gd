class_name Room
extends Node2D
## Thin controller attached to every room scene. The room's LAYOUT lives in the
## scene (a painted Floor/Walls TileMapLayer + placed entity prefabs + Spawn
## markers), edited visually in the editor. This script only spawns the player
## at the right entry marker, sizes the camera to the map, and (optionally)
## plays the intro.

const PlayerScene := preload("res://player/Player.tscn")

@export var play_intro := false


func _ready() -> void:
	add_to_group("room")
	_spawn_player()
	if play_intro and not GameState.has_flag("intro_played"):
		GameState.set_flag("intro_played", true)
		call_deferred("_run_intro")


func _spawn_player() -> void:
	var player := PlayerScene.instantiate()
	add_child(player)
	var marker := _find_spawn(World.consume_spawn())
	if marker != null:
		player.global_position = marker.global_position
	_apply_camera_limits(player)


## Spawn markers are Marker2D children of a "Spawns" node, named by id.
## Falls back to a marker named "default".
func _find_spawn(id: StringName) -> Node2D:
	var spawns := get_node_or_null("Spawns")
	if spawns == null:
		return null
	if id != &"":
		var m := spawns.get_node_or_null(String(id)) as Node2D
		if m != null:
			return m
	return spawns.get_node_or_null("default") as Node2D


func _apply_camera_limits(player: Node) -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	var floor_layer := get_node_or_null("Floor") as TileMapLayer
	if cam == null or floor_layer == null:
		return
	var rect := floor_layer.get_used_rect()
	var tsz := floor_layer.tile_set.tile_size
	cam.limit_left = rect.position.x * tsz.x
	cam.limit_top = rect.position.y * tsz.y
	cam.limit_right = (rect.position.x + rect.size.x) * tsz.x
	cam.limit_bottom = (rect.position.y + rect.size.y) * tsz.y


# --- Intro cutscene (proves the control-mode handoff) ----------------------

## Public entry so the debug overlay can replay it.
func trigger_intro() -> void:
	_run_intro()


func _run_intro() -> void:
	await Cutscene.play(_intro_sequence)


func _intro_sequence() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)

	var title := Label.new()
	title.text = "A COURT OF JESTERS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -120
	title.offset_right = 120
	title.offset_top = -16
	title.offset_bottom = 16
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(title)

	var sub := Label.new()
	sub.text = "The court awaits...   ( [E] to begin )"
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.offset_left = -120
	sub.offset_right = 120
	sub.offset_top = 6
	sub.offset_bottom = 22
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(sub)

	await _wait_or_skip(3.0)
	layer.queue_free()


func _wait_or_skip(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
