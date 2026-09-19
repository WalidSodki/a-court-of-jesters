extends Node
## Plays a sequence of dialogue "lines" and branching choices, driving a
## code-built dialogue box. Sets control mode to DIALOGUE while active so the
## player is disabled without touching the player script.
##
## A line is a Dictionary. Supported shapes:
##   {"speaker": "Steward", "text": "Well met, jester."}
##   {"text": "A plain narration line."}
##   {"text": "Question?", "choice": [
##       {"text": "Bow",  "flag": "steward_impressed", "value": true},
##       {"text": "Mock", "flag": "steward_impressed", "value": false, "call": some_callable},
##   ]}
##   {"call": some_callable}   # side effect (e.g. give an item), auto-advances

signal finished

var _canvas: CanvasLayer
var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _hint_label: Label

var _lines: Array = []
var _index := 0
var _active := false
var _awaiting_choice := false
var _choices: Array = []
var _choice_index := 0


func _ready() -> void:
	_build_ui()


func is_active() -> bool:
	return _active


func start(lines: Array) -> void:
	if _active:
		return
	_lines = lines.duplicate()
	_index = 0
	_active = true
	GameState.push_mode(GameState.Mode.DIALOGUE)
	_canvas.visible = true
	_show_current()


func _show_current() -> void:
	# Run any side-effect entries inline, then land on the next displayable one.
	while _index < _lines.size() and (_lines[_index] as Dictionary).has("call") \
			and not (_lines[_index] as Dictionary).has("choice") \
			and not (_lines[_index] as Dictionary).has("text"):
		(_lines[_index]["call"] as Callable).call()
		_index += 1

	if _index >= _lines.size():
		_end()
		return

	var line: Dictionary = _lines[_index]
	_name_label.text = line.get("speaker", "")
	_name_label.visible = _name_label.text != ""
	_text_label.text = line.get("text", "")
	AudioManager.play_sfx(&"dialogue")

	if line.has("choice"):
		_show_choices(line["choice"])
	else:
		_awaiting_choice = false
		_choice_box.visible = false
		_hint_label.text = "[E] continue"


func _show_choices(options: Array) -> void:
	_awaiting_choice = true
	_choices = options
	_choice_index = 0
	_choice_box.visible = true
	for c in _choice_box.get_children():
		c.queue_free()
	for opt in options:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 9)
		_choice_box.add_child(l)
	_refresh_choice_highlight()
	_hint_label.text = "[Up/Down] choose   [E] select"


func _refresh_choice_highlight() -> void:
	var children := _choice_box.get_children()
	for i in children.size():
		var l := children[i] as Label
		var selected := i == _choice_index
		l.text = ("> " if selected else "   ") + String(_choices[i].get("text", ""))
		l.modulate = Color(1, 0.9, 0.5) if selected else Color(0.7, 0.7, 0.7)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _awaiting_choice:
		if event.is_action_pressed("move_down"):
			_choice_index = wrapi(_choice_index + 1, 0, _choices.size())
			_refresh_choice_highlight()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_up"):
			_choice_index = wrapi(_choice_index - 1, 0, _choices.size())
			_refresh_choice_highlight()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			_confirm_choice()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
		_index += 1
		_show_current()
		get_viewport().set_input_as_handled()


func _confirm_choice() -> void:
	var opt: Dictionary = _choices[_choice_index]
	if opt.has("flag"):
		GameState.set_flag(opt["flag"], opt.get("value", true))
	if opt.has("call"):
		(opt["call"] as Callable).call()
	_awaiting_choice = false
	_index += 1
	_show_current()


func _end() -> void:
	_active = false
	_awaiting_choice = false
	_canvas.visible = false
	GameState.pop_mode()
	finished.emit()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 50
	_canvas.visible = false
	add_child(_canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 6
	_panel.offset_right = -6
	_panel.offset_top = -88
	_panel.offset_bottom = -6
	_panel.add_theme_stylebox_override("panel", _box_style())
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 9)
	_name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	vbox.add_child(_name_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 9)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(_text_label)

	_choice_box = VBoxContainer.new()
	_choice_box.visible = false
	vbox.add_child(_choice_box)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 7)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint_label)


func _box_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 0.94)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(6)
	sb.border_color = Color(0.8, 0.7, 0.4, 0.5)
	sb.set_border_width_all(1)
	return sb
