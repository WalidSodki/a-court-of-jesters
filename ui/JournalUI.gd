extends Node
## Code-built journal screen. Opens on the "journal" action (sets mode MENU) and
## lists the clues the player has discovered, with a description for the selected
## entry. Read-only for now; deductions (combining clues) come later. Mirrors the
## lifecycle of InventoryUI so both menus behave the same way.

var _canvas: CanvasLayer
var _dim: ColorRect
var _list: VBoxContainer
var _info_label: Label
var _hint_label: Label
var _rows: Array[Label] = []

var _open := false
var _cursor := 0


func _ready() -> void:
	_build_ui()
	Clues.changed.connect(_on_clues_changed)


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or not GameState.is_exploring():
		return
	_open = true
	_cursor = 0
	GameState.push_mode(GameState.Mode.MENU)
	_canvas.visible = true
	_rebuild()


func close() -> void:
	if not _open:
		return
	_open = false
	_canvas.visible = false
	GameState.pop_mode()


func _on_clues_changed() -> void:
	if _open:
		_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if GameState.is_exploring() and event.is_action_pressed("journal"):
			open()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("journal") or event.is_action_pressed("cancel"):
		close()
	elif event.is_action_pressed("move_down"):
		_move_cursor(1)
	elif event.is_action_pressed("move_up"):
		_move_cursor(-1)
	else:
		return
	get_viewport().set_input_as_handled()


func _move_cursor(delta: int) -> void:
	if Clues.discovered.is_empty():
		return
	_cursor = clampi(_cursor + delta, 0, Clues.discovered.size() - 1)
	AudioManager.play_sfx(&"ui")
	_refresh_highlights()
	_refresh_info()


func _current_clue() -> ClueData:
	if _cursor >= 0 and _cursor < Clues.discovered.size():
		return Clues.discovered[_cursor]
	return null


# --- UI construction -------------------------------------------------------

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 60
	_canvas.visible = false
	add_child(_canvas)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_stylebox_override("panel", _box_style())
	panel.offset_left = -110
	panel.offset_right = 110
	panel.offset_top = -74
	panel.offset_bottom = 74
	_canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Journal"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	vbox.add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 1)
	_list.custom_minimum_size = Vector2(200, 60)
	vbox.add_child(_list)

	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 8)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(200, 30)
	_info_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	vbox.add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.text = "[Up/Down] browse   [J] close"
	_hint_label.add_theme_font_size_override("font_size", 7)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(_hint_label)


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()

	if Clues.discovered.is_empty():
		var empty := Label.new()
		empty.text = "(no clues yet - go investigate)"
		empty.add_theme_font_size_override("font_size", 9)
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		_list.add_child(empty)
		_info_label.text = ""
		return

	_cursor = clampi(_cursor, 0, Clues.discovered.size() - 1)
	for clue in Clues.discovered:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 9)
		_list.add_child(row)
		_rows.append(row)

	_refresh_highlights()
	_refresh_info()


func _refresh_highlights() -> void:
	for i in _rows.size():
		var clue := Clues.discovered[i]
		var selected := i == _cursor
		_rows[i].text = ("> " if selected else "   ") + clue.title
		_rows[i].modulate = Color(1, 0.9, 0.5) if selected else Color(0.75, 0.75, 0.8)


func _refresh_info() -> void:
	var clue := _current_clue()
	if clue == null:
		_info_label.text = ""
		return
	var cat := "" if clue.category == "" else "[%s]\n" % clue.category
	_info_label.text = "%s%s" % [cat, clue.description]


func _box_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 0.97)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(7)
	sb.border_color = Color(0.8, 0.7, 0.4, 0.6)
	sb.set_border_width_all(1)
	return sb
