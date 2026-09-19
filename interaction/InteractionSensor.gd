class_name InteractionSensor
extends Area2D
## Detects nearby Interactables, picks the nearest, shows a floating prompt,
## and triggers it on the "interact" action. One code path for every
## interactable in the world.

@export var prompt_offset: Vector2 = Vector2(0, -20)

var _nearby: Array[Interactable] = []
var current: Interactable

# Prevents the same "interact" press that closed a dialogue/menu from instantly
# re-triggering the interactable in the same frame. Cleared once the button is
# released while exploring.
var _locked := false

var _prompt: Label


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_prompt()


func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.z_index = 50
	_prompt.visible = false
	add_child(_prompt)


func _on_area_entered(a: Area2D) -> void:
	if a is Interactable:
		_nearby.append(a)


func _on_area_exited(a: Area2D) -> void:
	if a is Interactable:
		_nearby.erase(a)
		if current == a:
			current = null


func _process(_delta: float) -> void:
	_update_current()
	_update_prompt()

	# Re-arm only once the button is released while we're back in control.
	if not GameState.is_exploring():
		_locked = true
	elif not Input.is_action_pressed("interact"):
		_locked = false

	if current != null and GameState.is_exploring() and not _locked \
			and Input.is_action_just_pressed("interact"):
		current.interact(owner)


func _update_current() -> void:
	var best: Interactable = null
	var best_dist := INF
	for it in _nearby:
		if not is_instance_valid(it) or not it.enabled:
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_dist:
			best_dist = d
			best = it
	current = best


func _update_prompt() -> void:
	var show := current != null and GameState.is_exploring()
	_prompt.visible = show
	if not show:
		return
	_prompt.text = "%s  %s" % [_button_hint(), current.get_prompt()]
	# Gentle bob so the prompt reads as interactive.
	var bob := sin(Time.get_ticks_msec() / 180.0) * 1.5
	_prompt.reset_size()
	_prompt.global_position = current.global_position + prompt_offset \
		- Vector2(_prompt.size.x * 0.5, 0) + Vector2(0, bob)


func _button_hint() -> String:
	# Keyboard label; a controller glyph goes here once art exists.
	return "[E]"
