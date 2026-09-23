extends Node
## Plays dialogue through a code-built dialogue box, and sets control mode to
## DIALOGUE while active so the player is disabled without touching the player
## script. Two authoring paths share the same box and input handling:
##
## 1. Data graphs — `start_conversation(ConversationData)`: nodes with
##    conditions, effects, choices, and `goto` links. The writer-facing path.
## 2. Inline arrays — `start(Array)`: quick Dictionaries built in GDScript, for
##    one-off lines and prompts. Kept for existing callers.
##
## Inline line shapes:
##   {"speaker": "Steward", "text": "..."}      # spoken line
##   {"text": "A narration line."}               # no speaker
##   {"text": "Q?", "choice": [                  # branch (rejoins after)
##       {"text": "Bow",  "flag": "impressed", "value": true},
##       {"text": "Mock", "flag": "impressed", "value": false, "call": cb}]}
##   {"call": some_callable}                      # side effect, auto-advances

signal finished

var _canvas: CanvasLayer
var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _hint_label: Label

var _active := false

# Conversation-graph state (null when running an inline array).
var _conv: ConversationData

# Inline-array state.
var _lines: Array = []
var _index := 0

# Shared choice state. Each entry is {"text": String, "select": Callable}.
var _awaiting_choice := false
var _choices: Array = []
var _choice_index := 0


func _ready() -> void:
	_build_ui()


func is_active() -> bool:
	return _active


# --- Public entry points ---------------------------------------------------

## Walk a data-authored conversation graph.
func start_conversation(conv: ConversationData) -> void:
	if _active or conv == null:
		return
	_conv = conv
	_begin()
	_present_from(0)


## Play a flat array of inline line Dictionaries (see header).
func start(lines: Array) -> void:
	if _active:
		return
	_conv = null
	_lines = lines.duplicate()
	_index = 0
	_begin()
	_show_current()


func _begin() -> void:
	_active = true
	_awaiting_choice = false
	GameState.push_mode(GameState.Mode.DIALOGUE)
	_canvas.visible = true


# --- Conversation-graph walk -----------------------------------------------

func _present_from(start_index: int) -> void:
	var i := start_index
	while i >= 0 and i < _conv.nodes.size():
		var node: DialogueNode = _conv.nodes[i]
		if node.condition != null and not node.condition.passes():
			i += 1
			continue
		if node.once and GameState.has_flag(_seen_key(node)):
			i += 1
			continue
		if node.once:
			GameState.set_flag(_seen_key(node), true)
		if node.effect != null:
			node.effect.apply()

		var options := _visible_choices(node)
		if node.text == "" and options.is_empty():
			# Pure side-effect node: apply and move on without pausing.
			i = _next_index(node, i)
			continue

		_index = i
		_display_node(node, options)
		return
	_end()


func _display_node(node: DialogueNode, options: Array) -> void:
	_name_label.text = node.speaker
	_name_label.visible = node.speaker != ""
	_text_label.text = node.text
	AudioManager.play_sfx(&"dialogue")

	if options.is_empty():
		_show_no_choices()
	else:
		_build_choices(_node_choice_entries(node, options))


func _advance_conversation() -> void:
	var node: DialogueNode = _conv.nodes[_index]
	_present_from(_next_index(node, _index))


func _visible_choices(node: DialogueNode) -> Array:
	var out: Array = []
	for c in node.choices:
		if c != null and (c.condition == null or c.condition.passes()):
			out.append(c)
	return out


func _node_choice_entries(node: DialogueNode, options: Array) -> Array:
	var entries: Array = []
	for opt in options:
		var choice: DialogueChoice = opt
		entries.append({
			"text": choice.text,
			"select": func() -> void:
				if choice.effect != null:
					choice.effect.apply()
				_present_from(_choice_next_index(choice, node)),
		})
	return entries


func _next_index(node: DialogueNode, i: int) -> int:
	if node.goto == &"end":
		return -1
	if node.goto != &"":
		return _conv.find_index(node.goto)
	return i + 1


func _choice_next_index(choice: DialogueChoice, node: DialogueNode) -> int:
	if choice.goto == &"end":
		return -1
	if choice.goto != &"":
		return _conv.find_index(choice.goto)
	return _next_index(node, _index)


func _seen_key(node: DialogueNode) -> String:
	return "seen/%s/%s" % [String(_conv.id), String(node.id)]


# --- Inline-array walk (legacy) --------------------------------------------

func _show_current() -> void:
	# Run any side-effect-only entries inline, then land on the next displayable.
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
		_build_choices(_inline_choice_entries(line["choice"]))
	else:
		_show_no_choices()


func _advance_inline() -> void:
	_index += 1
	_show_current()


func _inline_choice_entries(options: Array) -> Array:
	var entries: Array = []
	for opt in options:
		var o: Dictionary = opt
		entries.append({
			"text": String(o.get("text", "")),
			"select": func() -> void:
				if o.has("flag"):
					GameState.set_flag(o["flag"], o.get("value", true))
				if o.has("call"):
					(o["call"] as Callable).call()
				_index += 1
				_show_current(),
		})
	return entries


# --- Shared choice UI + input ----------------------------------------------

func _show_no_choices() -> void:
	_awaiting_choice = false
	_choice_box.visible = false
	_hint_label.text = "[E] continue"


func _build_choices(entries: Array) -> void:
	_awaiting_choice = true
	_choices = entries
	_choice_index = 0
	_choice_box.visible = true
	for c in _choice_box.get_children():
		c.queue_free()
	for _entry in entries:
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
		l.text = ("> " if selected else "   ") + String(_choices[i]["text"])
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
		if _conv != null:
			_advance_conversation()
		else:
			_advance_inline()
		get_viewport().set_input_as_handled()


func _confirm_choice() -> void:
	_awaiting_choice = false
	_choice_box.visible = false
	var select: Callable = _choices[_choice_index]["select"]
	select.call()


func _end() -> void:
	_active = false
	_awaiting_choice = false
	_conv = null
	_canvas.visible = false
	GameState.pop_mode()
	finished.emit()


# --- UI construction -------------------------------------------------------

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
