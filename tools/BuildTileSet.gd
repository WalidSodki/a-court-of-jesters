extends Node
## Dev-only: builds the shared TileSet asset (atlas + per-tile wall collision)
## and saves it as a real .tres you edit in the editor going forward.
##   godot --path . res://tools/BuildTileSet.tscn

const OUT := "res://world/tileset/court_tileset.tres"
const TS := 16

# Tiles that should be solid (brick/stone walls). Painting any of these on a
# layer with collision enabled makes it a wall. Add more in the editor anytime.
const WALL_TILES := [1, 2, 3, 13, 14, 15, 25, 26, 27, 57, 58, 59]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://world/tileset"))

	var sheet: Texture2D = load(Art.SHEET_PATH)
	var cols := int(sheet.get_width() / TS)
	var rows := int(sheet.get_height() / TS)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TS, TS)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)  # walls live on layer 1
	tile_set.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = sheet
	src.texture_region_size = Vector2i(TS, TS)
	for y in rows:
		for x in cols:
			src.create_tile(Vector2i(x, y))
	tile_set.add_source(src, 0)

	var square := PackedVector2Array([
		Vector2(-TS / 2.0, -TS / 2.0), Vector2(TS / 2.0, -TS / 2.0),
		Vector2(TS / 2.0, TS / 2.0), Vector2(-TS / 2.0, TS / 2.0),
	])
	for index in WALL_TILES:
		var coord := Vector2i(index % cols, index / cols)
		var td := src.get_tile_data(coord, 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, square)

	var err := ResourceSaver.save(tile_set, OUT)
	print("TileSet saved to %s (err %d), %d tiles, %d wall tiles" % [OUT, err, cols * rows, WALL_TILES.size()])
	get_tree().quit()
