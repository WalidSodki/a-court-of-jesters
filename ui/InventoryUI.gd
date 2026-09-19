extends Node
## Code-built inventory screen. Opens on the "inventory" action (sets mode
## MENU), shows items as a grid, and supports the two Milestone 1 verbs:
##   - Combine: select two combinable items -> recipe result
##   - Use: mark one item as "held" to use on a world object (e.g. the stage)

const COLUMNS := 4
const CELL := 34

var _canvas: CanvasLayer
var _dim: ColorRect
var _grid: GridContainer
var _info_label: Label
var _hint_label: Label
var _cells: Array[PanelContainer] = []

var _open := false
var _cursor := 0
var _combine_selection: Array[ItemData] = []


func _ready() -> void:
	_build_ui()
	Inventory.changed.connect(_on_inventory_changed)


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or not GameState.is_exploring():
		return
	_open = true
	_cursor = 0
	_combine_selection.clear()
	GameState.push_mode(GameState.Mode.MENU)
	_canvas.visible = true
	_rebuild()


func close() -> void:
	if not _open:
		return
	_open = false
	_canvas.visible = false
	GameState.pop_mode()


func _on_inventory_changed() -> void:
	if _open:
		_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		# Allow opening from anywhere while exploring.
		if GameState.is_exploring() and event.is_action_pressed("inventory"):
			open()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory") or event.is_action_pressed("cancel"):
		close()
	elif event.is_action_pressed("move_right"):
		_move_cursor(1)
	elif event.is_action_pressed("move_left"):
		_move_cursor(-1)
	elif event.is_action_pressed("move_down"):
		_move_cursor(COLUMNS)
	elif event.is_action_pressed("move_up"):
		_move_cursor(-COLUMNS)
	elif event.is_action_pressed("interact"):
		_toggle_combine()
	elif event.is_action_pressed("run"):
		_use_current()
	else:
		return
	get_viewport().set_input_as_handled()


func _move_cursor(delta: int) -> void:
	if Inventory.items.is_empty():
		return
	_cursor = clampi(_cursor + delta, 0, Inventory.items.size() - 1)
	AudioManager.play_sfx(&"ui")
	_refresh_highlights()
	_refresh_info()


func _current_item() -> ItemData:
	if _cursor >= 0 and _cursor < Inventory.items.size():
		return Inventory.items[_cursor]
	return null


func _toggle_combine() -> void:
	var item := _current_item()
	if item == null or not item.combinable:
		return
	if _combine_selection.has(item):
		_combine_selection.erase(item)
	else:
		_combine_selection.append(item)
	if _combine_selection.size() == 2:
		var result := Inventory.combine(_combine_selection[0], _combine_selection[1])
		_combine_selection.clear()
		if result != null:
			AudioManager.play_sfx(&"combine")
			_flash_info("Combined into: %s!" % result.display_name, Color(0.6, 1, 0.6))
		else:
			AudioManager.play_sfx(&"error")
			_flash_info("Those don't combine.", Color(1, 0.6, 0.6))
	_refresh_highlights()
	_refresh_info()


func _use_current() -> void:
	var item := _current_item()
	if item == null:
		return
	Inventory.set_held(item)
	_flash_info("Holding: %s. Use it on something." % item.display_name, Color(1, 0.9, 0.5))
	close()


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
	# Center it manually (PRESET_CENTER anchors the pivot; size drives layout).
	panel.offset_left = -100
	panel.offset_right = 100
	panel.offset_top = -70
	panel.offset_bottom = 70
	_canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	vbox.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 3)
	vbox.add_child(_grid)

	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 8)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(190, 20)
	vbox.add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.text = "[E] select to combine   [Shift] use   [Tab] close"
	_hint_label.add_theme_font_size_override("font_size", 7)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(_hint_label)


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_cells.clear()

	if Inventory.items.is_empty():
		var empty := Label.new()
		empty.text = "(empty)"
		empty.add_theme_font_size_override("font_size", 9)
		_grid.add_child(empty)
		_info_label.text = ""
		return

	_cursor = clampi(_cursor, 0, Inventory.items.size() - 1)
	for item in Inventory.items:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(CELL, CELL)
		cell.add_theme_stylebox_override("panel", _cell_style(Color(0, 0, 0, 0)))
		var icon := TextureRect.new()
		icon.texture = item.get_icon()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(CELL - 6, CELL - 6)
		cell.add_child(icon)
		_grid.add_child(cell)
		_cells.append(cell)

	_refresh_highlights()
	_refresh_info()


func _refresh_highlights() -> void:
	for i in _cells.size():
		var border := Color(0, 0, 0, 0)
		if i == _cursor:
			border = Color(1, 0.9, 0.5)            # cursor
		elif _combine_selection.has(Inventory.items[i]):
			border = Color(0.5, 0.8, 1.0)          # picked for combine
		_cells[i].add_theme_stylebox_override("panel", _cell_style(border))


func _refresh_info() -> void:
	var item := _current_item()
	if item == null:
		_info_label.text = ""
		return
	_info_label.modulate = Color.WHITE
	var tag := "  (combinable)" if item.combinable else ""
	_info_label.text = "%s%s\n%s" % [item.display_name, tag, item.description]


func _flash_info(text: String, color: Color) -> void:
	_info_label.text = text
	_info_label.modulate = color


func _cell_style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.16, 0.9)
	sb.set_corner_radius_all(2)
	sb.set_border_width_all(1)
	sb.border_color = border
	return sb


func _box_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 0.97)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(7)
	sb.border_color = Color(0.8, 0.7, 0.4, 0.6)
	sb.set_border_width_all(1)
	return sb
