class_name RoomKit
extends RefCounted
## Small shared helpers used when generating/authoring rooms. Rooms themselves
## are now editor-authored scenes (see tools/BuildRooms.gd for the scaffolder).

const TS := Art.TILE_SIZE


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TS + TS * 0.5, cell.y * TS + TS * 0.5)


## Full-screen vignette (dark edges, clear centre) for mood.
static func make_vignette(strength: float = 0.5) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.45, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, strength)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 320
	tex.height = 200
	var rect := TextureRect.new()
	rect.name = "Vignette"
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	return layer
