class_name Torch
extends Node2D
## A placeable torch/brazier: shows a sprite in-editor; builds its flickering
## light + embers at runtime. Optionally reacts to a story flag (e.g. the stage
## torches that flare when the steward is impressed).

@export var lit := true
## If set, the torch is lit only while this flag equals `react_value`.
@export var react_flag: String = ""
@export var react_value := true
@export var base_energy := 1.1
@export var light_scale := 0.5

@onready var _sprite: Sprite2D = $Sprite
var _light: FlickerLight
var _embers: CPUParticles2D


func _ready() -> void:
	_light = FlickerLight.new()
	_light.base_energy = base_energy
	_light.texture_scale = light_scale
	add_child(_light)

	_embers = _make_embers()
	add_child(_embers)

	if react_flag != "":
		GameState.flag_changed.connect(_on_flag_changed)
		_set_lit(bool(GameState.get_flag(react_flag)) == react_value)
	else:
		_set_lit(lit)


func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == react_flag:
		_set_lit(bool(value) == react_value)


func _set_lit(value: bool) -> void:
	_light.set_lit(value)
	_embers.emitting = value
	if _sprite != null:
		_sprite.modulate.a = 1.0 if value else 0.5


func _make_embers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -4)
	p.amount = 10
	p.lifetime = 1.1
	p.local_coords = false
	p.spread = 20.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 10.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.color = Color(1.0, 0.65, 0.25, 0.8)
	return p
