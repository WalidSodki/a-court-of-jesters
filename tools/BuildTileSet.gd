extends Node
## Dev-only: builds the shared TileSet asset and saves it as a real .tres you
## edit in the editor going forward.
##   godot --path . res://tools/BuildTileSet.tscn
##
## Collision is LAYER-BASED, not per-tile: EVERY tile carries a full-cell
## collision shape, so solidity is decided by which TileMapLayer a tile is on.
## The Walls layer keeps collision enabled (solid); the Floor layer disables it
## (walkable). This means "paint on Walls = solid" for any art — see BuildRooms.

const OUT := "res://world/tileset/court_tileset.tres"
# Stable UID so room scenes keep resolving this asset across rebuilds.
const OUT_UID := "uid://8b1d7n7q0kvp"
const TS := 16


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
	# Every tile gets a full-cell collider; the LAYER decides if it's used.
	for y in rows:
		for x in cols:
			var td := src.get_tile_data(Vector2i(x, y), 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)

	var err := ResourceSaver.save(tile_set, OUT)
	_pin_uid()
	print("TileSet saved to %s (err %d, uid %s), %d tiles (all solid; layer decides)" % [OUT, err, OUT_UID, cols * rows])
	get_tree().quit()


## ResourceSaver drops the UID; write a stable one into the header so room
## scenes that reference this asset by UID keep resolving across rebuilds.
func _pin_uid() -> void:
	var f := FileAccess.open(OUT, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	if text.contains("uid="):
		return
	text = text.replace(
		'[gd_resource type="TileSet" format=3]',
		'[gd_resource type="TileSet" format=3 uid="%s"]' % OUT_UID)
	var w := FileAccess.open(OUT, FileAccess.WRITE)
	w.store_string(text)
	w.close()
