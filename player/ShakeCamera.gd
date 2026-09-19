class_name ShakeCamera
extends Camera2D
## Camera with a reusable trauma-style shake. Call shake(px, seconds) on impacts
## and scares. Works alongside position smoothing (shake drives `offset`).

var _amount := 0.0
var _decay := 0.0


func shake(amount: float, time: float = 0.3) -> void:
	_amount = maxf(_amount, amount)
	_decay = amount / maxf(time, 0.01)


func _process(delta: float) -> void:
	if _amount <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	offset = Vector2(randf_range(-_amount, _amount), randf_range(-_amount, _amount))
	_amount = maxf(0.0, _amount - _decay * delta)
