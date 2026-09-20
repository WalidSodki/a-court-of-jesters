class_name StealthController
extends Node2D
## Coordinates a stealth section. It discovers the room's guards, shows one
## shared detection meter (the max across guards), and owns the caught outcome —
## keeping that logic out of the guards, which only report via signals.
##
## Caught outcome (design decision M3): FLAG + RETRY. Getting spotted records a
## flag later content can read, then plays a short scare and respawns the player
## at the section entrance with the guards reset — no progress is lost.
##
## Extends Node2D only so the room scaffolder can place it like any entity; it
## has no world position of its own (its UI is a screen-space CanvasLayer).

## Which Spawns/Marker2D to send the player back to when caught.
@export var respawn_spawn_id: StringName = &"default"

var _guards: Array[Guard] = []
var _level := 0.0
var _resetting := false

var _canvas: CanvasLayer
var _meter_fill: ColorRect
var _meter_root: Control
var _flash: ColorRect


func _ready() -> void:
	# Wait a frame so guards and the player are in the tree before we hook up.
	call_deferred("_setup")


func _setup() -> void:
	for g in get_tree().get_nodes_in_group("guard"):
		if g is Guard:
			_guards.append(g)
			(g as Guard).caught.connect(_on_caught)
	_build_ui()


func _process(_delta: float) -> void:
	var m := 0.0
	for g in _guards:
		if is_instance_valid(g):
			m = maxf(m, g.get_detection())
	_level = m
	_update_meter()


func _on_caught() -> void:
	if _resetting:
		return
	_resetting = true
	await _caught_sequence()
	_resetting = false


func _caught_sequence() -> void:
	GameState.set_flag("caught_sneaking", true)
	var count := int(GameState.get_flag("sneak_caught_count", 0)) + 1
	GameState.set_flag("sneak_caught_count", count)
	await Cutscene.play(func() -> void:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("shake_camera"):
			player.shake_camera(4.0, 0.4)
		AudioManager.play_sfx(&"error")
		_alarm_flash()
		Dialogue.start([{"speaker": "Guard", "text": "Halt! You there — stop where you stand!"}])
		await Dialogue.finished
		await Transitions.fade_out(0.4)
		_respawn()
		Transitions.fade_in(0.4)
	)


func _respawn() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var room := get_tree().get_first_node_in_group("room") as Node
	if player != null and room != null:
		var spawns := room.get_node_or_null("Spawns")
		var marker: Node2D = null
		if spawns != null:
			marker = spawns.get_node_or_null(String(respawn_spawn_id)) as Node2D
			if marker == null:
				marker = spawns.get_node_or_null("default") as Node2D
		if marker != null:
			player.global_position = marker.global_position
	for g in _guards:
		if is_instance_valid(g):
			g.reset()
	_level = 0.0
	_update_meter()


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 45
	add_child(_canvas)

	_flash = ColorRect.new()
	_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_flash)

	_meter_root = Control.new()
	_meter_root.position = Vector2(100, 10)
	_meter_root.visible = false
	_canvas.add_child(_meter_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.position = Vector2(-1, -1)
	bg.size = Vector2(122, 8)
	_meter_root.add_child(bg)

	_meter_fill = ColorRect.new()
	_meter_fill.color = Color(1, 0.85, 0.3)
	_meter_fill.size = Vector2(0, 6)
	_meter_root.add_child(_meter_fill)

	var label := Label.new()
	label.text = "ALERT"
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label.position = Vector2(0, 8)
	_meter_root.add_child(label)


func _update_meter() -> void:
	if _meter_fill == null:
		return
	_meter_root.visible = _level > 0.01
	_meter_fill.size.x = 120.0 * _level
	_meter_fill.color = Color(1, 0.85, 0.3).lerp(Color(1, 0.2, 0.15), _level)


func _alarm_flash() -> void:
	if _flash == null:
		return
	_flash.color.a = 0.6
	var t := create_tween()
	t.tween_property(_flash, "color:a", 0.0, 0.5)
