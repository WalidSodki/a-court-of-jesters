class_name ChaseController
extends Node
## Coordinates a flee/chase section. It discovers the room's chasers, shows one
## shared danger meter (the max proximity across chasers), and owns the caught
## outcome — keeping that logic out of the chasers, which only report via signals.
##
## Caught outcome (design decision M4, mirroring stealth): FLAG + RETRY. Getting
## caught records a flag later content can read, then plays a short scare and
## respawns the player at the section entrance with the chasers reset — no
## progress is lost. Escaping is implicit: reaching the room's exit Door unloads
## the room (and this controller); the success flag is set at the destination.

## Which Spawns/Marker2D to send the player back to when caught.
@export var respawn_spawn_id: StringName = &"default"

var _chasers: Array[Chaser] = []
var _levels: Dictionary = {}   # chaser -> its latest proximity (0..1)
var _level := 0.0
var _resetting := false

var _canvas: CanvasLayer
var _meter_fill: ColorRect
var _meter_root: Control
var _banner: Label
var _flash: ColorRect


func _ready() -> void:
	# Wait a frame so chasers and the player are in the tree before we hook up.
	call_deferred("_setup")


func _setup() -> void:
	for c in get_tree().get_nodes_in_group("chaser"):
		if c is Chaser:
			var chaser := c as Chaser
			_chasers.append(chaser)
			_levels[chaser] = chaser.get_proximity()
			chaser.caught.connect(_on_caught)
			chaser.proximity_changed.connect(_on_chaser_proximity.bind(chaser))
	_build_ui()
	AudioManager.play_sfx(&"error")   # an ominous sting as the chase begins


## Driven by each chaser's proximity_changed — no per-frame polling.
func _on_chaser_proximity(level: float, chaser: Chaser) -> void:
	_levels[chaser] = level
	var m := 0.0
	for v in _levels.values():
		m = maxf(m, v)
	_level = m
	_update_meter()


func _on_caught() -> void:
	if _resetting:
		return
	_resetting = true
	await _caught_sequence()
	_resetting = false


func _caught_sequence() -> void:
	GameState.set_flag("caught_fleeing", true)
	var count := int(GameState.get_flag("flee_caught_count", 0)) + 1
	GameState.set_flag("flee_caught_count", count)
	await Cutscene.play(func() -> void:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("shake_camera"):
			player.shake_camera(5.0, 0.45)
		AudioManager.play_sfx(&"error")
		_alarm_flash()
		Dialogue.start([{"speaker": "???", "text": "A cold hand closes on your shoulder..."}])
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
	for c in _chasers:
		if is_instance_valid(c):
			c.reset()
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

	_banner = Label.new()
	_banner.text = "RUN!"
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.add_theme_color_override("font_color", Color(1, 0.3, 0.25))
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 4)
	_banner.position = Vector2(138, 6)
	_canvas.add_child(_banner)

	_meter_root = Control.new()
	_meter_root.position = Vector2(100, 28)
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
	label.text = "DANGER"
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
