extends Node
## Dev-only: generates the editable room scenes (painted TileMapLayers + placed
## entity prefab instances + spawn markers) and saves them as .tscn. After this
## runs, level design happens in the editor; this tool is only for re-scaffolding.
##   godot --path . res://tools/BuildRooms.tscn

const TILESET := "res://world/tileset/court_tileset.tres"
const OUT_DIR := "res://world/"

## Safety: by default this scaffolder only creates rooms that don't exist yet, so
## re-running it can never clobber a room you've since hand-edited in the editor.
## Flip to true (temporarily) only when you deliberately want to regenerate.
const FORCE_REBUILD := false

const BELLS := "res://items/bells.tres"
const STICK := "res://items/stick.tres"
const BATON := "res://items/baton.tres"

const GREAT_HALL_MAP := [
	"####################",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"####################",
]

const ANTECHAMBER_MAP := [
	"#############",
	"#...........#",
	"#...........#",
	"#...........#",
	"#...........#",
	"#...........#",
	"#...........#",
	"#...........#",
	"#...........#",
	"#############",
]

# Stealth gauntlet: a long horizontal corridor. Enter left, reach the exit door
# on the right past a line of guards that sweep vertically on fixed paths — a
# predictable rhythm of moving sight-cones to time your dashes through. Two cover
# pillars give mid-corridor hiding spots. Built in code so the wide grid can't be
# miscounted; see _passage_map().
const PASSAGE_W := 45
const PASSAGE_H := 12
# Guard lanes (columns) and cover-pillar columns are kept disjoint so a guard
# never patrols into a pillar.
const PASSAGE_GUARD_COLS := [6, 11, 16, 21, 26, 31, 36]
const PASSAGE_PILLAR_COLS := [9, 34]

# Flee lane: a long open corridor. Enter left, a threat starts just behind you,
# outrun it to the exit door on the right. Deliberately open (no interior pillars)
# so the straight-line chaser reads fair and never wedges — see Chaser.gd.
const CHASE_W := 40
const CHASE_H := 11

# The closing throne room (a small chamber; the outro cutscene carries the beat).
const FINALE_MAP := [
	"###############",
	"#.............#",
	"#.............#",
	"#.............#",
	"#.............#",
	"#.............#",
	"#.............#",
	"#.............#",
	"#.............#",
	"###############",
]


func _ready() -> void:
	_build({
		"name": "GreatHall",
		"map": GREAT_HALL_MAP,
		"floor": 48,
		"night": Color(0.55, 0.52, 0.64),
		"vignette": 0.5,
		"play_intro": true,
		"spawns": {"default": Vector2i(10, 8), "from_antechamber": Vector2i(3, 3)},
		"entities": [
			{"scene": "res://entities/Steward.tscn", "name": "Steward", "cell": Vector2i(10, 3),
				"props": {"gift_item": load(STICK)}},
			{"scene": "res://entities/Chest.tscn", "name": "Chest", "cell": Vector2i(3, 3),
				"props": {"item": load(BELLS)}},
			{"scene": "res://entities/Pedestal.tscn", "name": "Pedestal", "cell": Vector2i(16, 3),
				"props": {"required_item": load(BATON)}},
			{"scene": "res://entities/Door.tscn", "name": "DoorToAntechamber", "cell": Vector2i(2, 1),
				"props": {"target_scene": "res://world/Antechamber.tscn", "spawn_id": &"from_hall"}},
			{"scene": "res://entities/Torch.tscn", "name": "TorchLeft", "cell": Vector2i(6, 1),
				"props": {"lit": true}},
			{"scene": "res://entities/Torch.tscn", "name": "TorchRight", "cell": Vector2i(13, 1),
				"props": {"lit": true}},
			{"scene": "res://entities/Torch.tscn", "name": "StageTorchL", "cell": Vector2i(14, 2),
				"props": {"lit": false, "react_flag": "steward_impressed", "react_value": true}},
			{"scene": "res://entities/Torch.tscn", "name": "StageTorchR", "cell": Vector2i(18, 2),
				"props": {"lit": false, "react_flag": "steward_impressed", "react_value": true}},
		],
	})

	_build({
		"name": "Antechamber",
		"map": ANTECHAMBER_MAP,
		"floor": 37,
		"night": Color(0.30, 0.30, 0.44),
		"vignette": 0.62,
		"play_intro": false,
		"spawns": {"default": Vector2i(6, 8), "from_hall": Vector2i(6, 8)},
		"entities": [
			{"scene": "res://entities/Door.tscn", "name": "DoorToHall", "cell": Vector2i(6, 1),
				"props": {"target_scene": "res://world/GreatHall.tscn", "spawn_id": &"from_antechamber", "prompt": "Return to hall"}},
			{"scene": "res://entities/Ghost.tscn", "name": "Ghost", "cell": Vector2i(6, 4),
				"props": {
					"speaker": "?",
					"lines": PackedStringArray(["A cold shape lingers by the wall. It watches you rehearse... and says nothing."]),
					"camera_shake": 2.0, "sfx": &"error", "prompt": "Examine",
				}},
			{"scene": "res://entities/ExamineSpot.tscn", "name": "Note", "cell": Vector2i(10, 7),
				"props": {
					"lines": PackedStringArray([
						"A torn note, the ink smeared:",
						"\"The last jester made the king laugh. Then he was never seen to leave. Mind which laughs you earn.\"",
					]),
					"set_story_flag": "read_note", "prompt": "Read",
				}},
			{"scene": "res://entities/Torch.tscn", "name": "TorchLeft", "cell": Vector2i(2, 1),
				"props": {"lit": true}},
			{"scene": "res://entities/Torch.tscn", "name": "TorchRight", "cell": Vector2i(10, 1),
				"props": {"lit": true}},
		],
	})

	_build({
		"name": "Passage",
		"map": _passage_map(),
		"floor": 37,
		"night": Color(0.24, 0.24, 0.38),
		"vignette": 0.62,
		"play_intro": false,
		"spawns": {"default": Vector2i(2, 6), "from_hall": Vector2i(2, 6)},
		"entities": _passage_entities(),
	})

	_build({
		"name": "Chase",
		"map": _chase_map(),
		"floor": 37,
		"night": Color(0.20, 0.18, 0.30),
		"vignette": 0.66,
		"play_intro": false,
		"spawns": {"default": Vector2i(5, 5)},
		"entities": _chase_entities(),
	})

	_build({
		"name": "Finale",
		"map": FINALE_MAP,
		"floor": 48,
		"night": Color(0.50, 0.46, 0.60),
		"vignette": 0.5,
		"play_intro": false,
		"script": "res://world/Finale.gd",
		"spawns": {"default": Vector2i(7, 8)},
		"entities": [
			{"scene": "res://entities/Torch.tscn", "name": "TorchLeft", "cell": Vector2i(4, 1),
				"props": {"lit": true}},
			{"scene": "res://entities/Torch.tscn", "name": "TorchRight", "cell": Vector2i(10, 1),
				"props": {"lit": true}},
		],
	})

	print("Rooms built.")
	get_tree().quit()


## The open flee corridor as an ASCII map: solid border, clear interior.
func _chase_map() -> Array:
	var rows: Array = []
	for y in CHASE_H:
		var s := ""
		for x in CHASE_W:
			var solid := x == 0 or x == CHASE_W - 1 or y == 0 or y == CHASE_H - 1
			s += "#" if solid else "."
		rows.append(s)
	return rows


## ChaseController + one Chaser starting a few tiles behind the entry spawn + the
## exit door (to the Finale) + torches. Escaping = reaching the exit door.
func _chase_entities() -> Array:
	return [
		{"scene": "res://entities/ChaseController.tscn", "name": "Chase", "cell": Vector2i(1, 1),
			"props": {"respawn_spawn_id": &"default"}},
		{"scene": "res://entities/Chaser.tscn", "name": "Chaser", "cell": Vector2i(2, 5),
			"props": {"speed": 82.0, "catch_distance": 12.0, "danger_distance": 90.0, "start_delay": 0.9}},
		{"scene": "res://entities/Door.tscn", "name": "ExitDoor", "cell": Vector2i(CHASE_W - 2, 5),
			"props": {"target_scene": "res://world/Finale.tscn", "spawn_id": &"default", "prompt": "Escape"}},
		{"scene": "res://entities/Torch.tscn", "name": "TorchStart", "cell": Vector2i(2, 1),
			"props": {"lit": true}},
		{"scene": "res://entities/Torch.tscn", "name": "TorchEnd", "cell": Vector2i(CHASE_W - 3, 1),
			"props": {"lit": true}},
	]


## The long stealth corridor as an ASCII map: solid border, plus 2-tall cover
## pillars in the pillar columns. Guard lanes are left clear.
func _passage_map() -> Array:
	var rows: Array = []
	for y in PASSAGE_H:
		var s := ""
		for x in PASSAGE_W:
			var solid := x == 0 or x == PASSAGE_W - 1 or y == 0 or y == PASSAGE_H - 1
			if x in PASSAGE_PILLAR_COLS and (y == 5 or y == 6):
				solid = true
			s += "#" if solid else "."
		rows.append(s)
	return rows


## StealthController + a line of vertically-sweeping guards (alternating start
## phase so gaps form a rhythm) + the exit door + torches.
func _passage_entities() -> Array:
	var sweep := Vector2(0, 7 * 16)   # patrol height: rows 2..9
	var ents: Array = [
		{"scene": "res://entities/StealthController.tscn", "name": "Stealth", "cell": Vector2i(1, 1),
			"props": {"respawn_spawn_id": &"default"}},
	]
	for i in PASSAGE_GUARD_COLS.size():
		var col: int = PASSAGE_GUARD_COLS[i]
		var top_start := i % 2 == 0                      # alternate phase
		var start_row := 2 if top_start else 9
		var offset := sweep if top_start else -sweep     # first leg direction
		ents.append({
			"scene": "res://entities/Guard.tscn", "name": "Guard%d" % (i + 1),
			"cell": Vector2i(col, start_row),
			"props": {
				"patrol_points": PackedVector2Array([Vector2.ZERO, offset]),
				"speed": 32.0, "wait_time": 0.4,
				"view_distance": 68.0, "view_angle_deg": 64.0,
			},
		})
	ents.append({"scene": "res://entities/Door.tscn", "name": "ExitDoor", "cell": Vector2i(PASSAGE_W - 2, 6),
		"props": {"target_scene": "res://world/GreatHall.tscn", "spawn_id": &"from_antechamber", "prompt": "Slip out"}})
	ents.append({"scene": "res://entities/Torch.tscn", "name": "TorchStart", "cell": Vector2i(2, 1),
		"props": {"lit": true}})
	ents.append({"scene": "res://entities/Torch.tscn", "name": "TorchEnd", "cell": Vector2i(PASSAGE_W - 3, 1),
		"props": {"lit": true}})
	return ents


func _build(def: Dictionary) -> void:
	var out: String = OUT_DIR + def.name + ".tscn"
	if not FORCE_REBUILD and FileAccess.file_exists(out):
		print("  %s.tscn exists — skipped (set FORCE_REBUILD to overwrite)" % def.name)
		return

	var tile_set: TileSet = load(TILESET)
	var root := Room.new()
	root.name = def.name
	# Rooms with extra behaviour use a Room subclass (e.g. Finale.gd's outro).
	if def.has("script"):
		root.set_script(load(def.script))
	root.play_intro = def.get("play_intro", false)

	var night := CanvasModulate.new()
	night.name = "Night"
	night.color = def.night
	root.add_child(night)

	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tile_set
	floor_layer.collision_enabled = false  # walkable: Floor never collides
	root.add_child(floor_layer)

	var wall_layer := TileMapLayer.new()
	wall_layer.name = "Walls"
	wall_layer.tile_set = tile_set
	wall_layer.collision_enabled = true    # solid: anything painted here blocks
	root.add_child(wall_layer)

	_paint(floor_layer, wall_layer, def.map, def.floor)

	var vignette := RoomKit.make_vignette(def.vignette)
	vignette.name = "Vignette"
	root.add_child(vignette)

	var entities := Node2D.new()
	entities.name = "Entities"
	root.add_child(entities)
	for e in def.entities:
		var inst: Node = load(e.scene).instantiate()
		inst.name = e.name
		if inst is Node2D:
			(inst as Node2D).position = RoomKit.cell_center(e.cell)
		for key in e.get("props", {}):
			inst.set(key, e.props[key])
		entities.add_child(inst)

	var spawns := Node2D.new()
	spawns.name = "Spawns"
	root.add_child(spawns)
	for id in def.spawns:
		var m := Marker2D.new()
		m.name = id
		m.position = RoomKit.cell_center(def.spawns[id])
		spawns.add_child(m)

	_set_owner(root, root)

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, out)
	print("  %s.tscn (pack %d, save %d)" % [def.name, perr, serr])
	root.free()


# The grey-brick nine-slice frame in the Kenney sheet (see room-tile-convention).
const WALL_TL := 1
const WALL_TOP := 2
const WALL_TR := 3
const WALL_LEFT := 13
const WALL_FILL := 14
const WALL_RIGHT := 15
const WALL_BL := 25
const WALL_BOTTOM := 26
const WALL_BR := 27


func _paint(floor_layer: TileMapLayer, wall_layer: TileMapLayer, map: Array, floor_index: int) -> void:
	var floor_coords := Vector2i(floor_index % 12, floor_index / 12)
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			floor_layer.set_cell(Vector2i(x, y), 0, floor_coords)
			if row[x] == "#":
				var wi := _wall_tile(map, x, y)
				wall_layer.set_cell(Vector2i(x, y), 0, Vector2i(wi % 12, wi / 12))


## Pick a nine-slice frame tile for a wall cell from which orthogonal neighbours
## are open floor (corners fall back to the inward diagonal). Enclosed cells and
## thin/1-wide pillars use the brick fill. NOTE: this is a lightweight autotiler
## for the placeholder art; when real tiles arrive, TileSet Terrains (authored in
## BuildTileSet + set_cells_terrain_connect) are the proper Godot way.
func _wall_tile(map: Array, x: int, y: int) -> int:
	var up := _open(map, x, y - 1)
	var down := _open(map, x, y + 1)
	var left := _open(map, x - 1, y)
	var right := _open(map, x + 1, y)
	var n := int(up) + int(down) + int(left) + int(right)
	if n == 1:
		if down: return WALL_TOP
		if up: return WALL_BOTTOM
		if right: return WALL_LEFT
		return WALL_RIGHT
	if n == 0:
		if _open(map, x + 1, y + 1): return WALL_TL
		if _open(map, x - 1, y + 1): return WALL_TR
		if _open(map, x + 1, y - 1): return WALL_BL
		if _open(map, x - 1, y - 1): return WALL_BR
	return WALL_FILL


## True if (x,y) is in bounds and NOT a wall. Out-of-bounds counts as solid, so
## the frame closes cleanly at the map edge.
func _open(map: Array, x: int, y: int) -> bool:
	if y < 0 or y >= map.size():
		return false
	var row: String = map[y]
	if x < 0 or x >= row.length():
		return false
	return row[x] != "#"


## Every tool-created node must be owned by the scene root to be saved. Instanced
## prefabs are owned at their root only (their internals belong to the prefab).
func _set_owner(node: Node, root: Node) -> void:
	for c in node.get_children():
		c.owner = root
		if c.scene_file_path == "":
			_set_owner(c, root)
