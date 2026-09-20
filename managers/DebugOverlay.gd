extends Node
## Dev-only overlay (debug builds). Toggle with F1 / Back. Shows live state and
## offers hotkeys to jump around so the demo is fast to iterate on.
##
## Hotkeys while visible:
##   1/2/3  grant Bells / Stick / Marotte
##   4      jump to the Passage (stealth section)
##   5/6    set steward_impressed true / false
##   7      jump straight into the court performance (rhythm minigame)
##   8      play the intro cutscene
##   9      toggle player noclip
##   0      reload the room

const ITEM_PATHS := {
	KEY_1: "res://items/bells.tres",
	KEY_2: "res://items/stick.tres",
	KEY_3: "res://items/baton.tres",
}
const PERFORM_CHART := preload("res://minigames/charts/court_debut.tres")

var _canvas: CanvasLayer
var _label: Label
var _visible := false
var _noclip := false


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	_build_ui()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 90
	add_child(_canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	_canvas.add_child(panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color(0.6, 1, 0.7))
	panel.add_child(_label)

	_canvas.visible = false


func _process(_delta: float) -> void:
	if not _visible:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var pos := player.global_position if player != null else Vector2.ZERO
	_label.text = "DEBUG  (F1)\nmode: %s\nfps: %d\npos: %d, %d\nnoclip: %s\nflags: %s\nitems: %s\nheld: %s\n[1/2/3] give  [4] passage  [5/6] steward  [7] perform  [8] intro  [9] noclip  [0] reload" % [
		GameState.mode_name(),
		Engine.get_frames_per_second(),
		pos.x, pos.y,
		str(_noclip),
		str(GameState.story_flags),
		str(_item_ids()),
		Inventory.held_item.display_name if Inventory.held_item != null else "-",
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_visible = not _visible
		_canvas.visible = _visible
		get_viewport().set_input_as_handled()
		return
	if not _visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key := (event as InputEventKey).keycode
	if ITEM_PATHS.has(key):
		Inventory.add(load(ITEM_PATHS[key]))
	elif key == KEY_4:
		World.go_to("res://world/Passage.tscn")
	elif key == KEY_5:
		GameState.set_flag("steward_impressed", true)
	elif key == KEY_6:
		GameState.set_flag("steward_impressed", false)
	elif key == KEY_7:
		if GameState.mode != GameState.Mode.MINIGAME:
			GameState.set_flag("stage_ready", true)
			await Perform.run(PERFORM_CHART)
	elif key == KEY_8:
		var room := get_tree().get_first_node_in_group("room")
		if room != null and room.has_method("trigger_intro"):
			room.trigger_intro()
	elif key == KEY_9:
		_toggle_noclip()
	elif key == KEY_0:
		World.reload()


func _toggle_noclip() -> void:
	_noclip = not _noclip
	var player := get_tree().get_first_node_in_group("player") as CollisionObject2D
	if player != null:
		player.collision_mask = 0 if _noclip else 1


func _item_ids() -> Array:
	var ids: Array = []
	for it in Inventory.items:
		ids.append(String(it.id))
	return ids
