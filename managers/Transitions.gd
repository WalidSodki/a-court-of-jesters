extends Node
## Full-screen fades for room enter/exit and cutscene bookends.
## Builds its own CanvasLayer so any scene can use it without setup.

var _canvas: CanvasLayer
var _rect: ColorRect


func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100  # above gameplay and most UI
	add_child(_canvas)

	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_canvas.add_child(_rect)


## Fade from black to clear (call when a room becomes visible).
func fade_in(duration: float = 0.5) -> void:
	_rect.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 0.0, duration)


## Fade to black. Await it before switching scenes.
func fade_out(duration: float = 0.5) -> void:
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 1.0, duration)
	await t.finished
