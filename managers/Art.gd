class_name Art
extends RefCounted
## Slices the placeholder Kenney sheet into 16x16 tiles by index.
##
## index = row * COLUMNS + column (row-major, matching the Tiles/ folder names).
## When final art arrives, swap SHEET_PATH (and/or set explicit textures on
## ItemData) — no gameplay code needs to change.

const SHEET_PATH := "res://art/royalty free placeholder/Tilemap/tilemap_packed.png"
const TILE_SIZE := 16
const COLUMNS := 12

# Loaded lazily so we never depend on import order at parse time.
static var _sheet: Texture2D


static func sheet() -> Texture2D:
	if _sheet == null:
		_sheet = load(SHEET_PATH)
	return _sheet


static func coords(index: int) -> Vector2i:
	return Vector2i(index % COLUMNS, index / COLUMNS)


static func region(index: int) -> Rect2:
	var c := coords(index)
	return Rect2(c.x * TILE_SIZE, c.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)


static func tile(index: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet()
	at.region = region(index)
	return at


# --- Shared radial light/glow texture (torches, player glow, vignette) ------
static var _light_tex: Texture2D


static func light_texture() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_light_tex = t
	return _light_tex
