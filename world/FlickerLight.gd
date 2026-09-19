class_name FlickerLight
extends PointLight2D
## A warm, gently flickering point light for torches/braziers. Can be dimmed
## (unlit) and lit; the flame reads as alive without hand-animation.

@export var base_energy: float = 1.0
@export var flicker_amount: float = 0.22
@export var warm: Color = Color(1.0, 0.72, 0.36)

var lit := true
var _t := randf() * 10.0


func _ready() -> void:
	texture = Art.light_texture()
	color = warm
	blend_mode = Light2D.BLEND_MODE_ADD
	shadow_enabled = false


func _process(delta: float) -> void:
	_t += delta * 12.0
	var target := 0.0
	if lit:
		target = base_energy + sin(_t) * flicker_amount + randf_range(-0.06, 0.06)
	energy = lerpf(energy, maxf(0.0, target), delta * 14.0)


func set_lit(value: bool) -> void:
	lit = value
