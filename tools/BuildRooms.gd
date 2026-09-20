extends Node
## Dev-only: generates the editable room scenes (painted TileMapLayers + placed
## entity prefab instances + spawn markers) and saves them as .tscn. After this
## runs, level design happens in the editor; this tool is only for re-scaffolding.
##   godot --path . res://tools/BuildRooms.tscn

const TILESET := "res://world/tileset/court_tileset.tres"
const OUT_DIR := "res://world/"

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


func _ready() -> void:
	_build({
		"name": "GreatHall",
		"map": GREAT_HALL_MAP,
		"floor": 48, "wall": 2,
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
		"floor": 37, "wall": 2,
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

	print("Rooms built.")
	get_tree().quit()


func _build(def: Dictionary) -> void:
	var tile_set: TileSet = load(TILESET)
	var root := Room.new()
	root.name = def.name
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

	_paint(floor_layer, wall_layer, def.map, def.floor, def.wall)

	var vignette := RoomKit.make_vignette(def.vignette)
	vignette.name = "Vignette"
	root.add_child(vignette)

	var entities := Node2D.new()
	entities.name = "Entities"
	root.add_child(entities)
	for e in def.entities:
		var inst: Node = load(e.scene).instantiate()
		inst.name = e.name
		inst.position = RoomKit.cell_center(e.cell)
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
	var serr := ResourceSaver.save(packed, OUT_DIR + def.name + ".tscn")
	print("  %s.tscn (pack %d, save %d)" % [def.name, perr, serr])
	root.free()


func _paint(floor_layer: TileMapLayer, wall_layer: TileMapLayer, map: Array, floor_index: int, wall_index: int) -> void:
	var floor_coords := Vector2i(floor_index % 12, floor_index / 12)
	var wall_coords := Vector2i(wall_index % 12, wall_index / 12)
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			floor_layer.set_cell(Vector2i(x, y), 0, floor_coords)
			if row[x] == "#":
				wall_layer.set_cell(Vector2i(x, y), 0, wall_coords)


## Every tool-created node must be owned by the scene root to be saved. Instanced
## prefabs are owned at their root only (their internals belong to the prefab).
func _set_owner(node: Node, root: Node) -> void:
	for c in node.get_children():
		c.owner = root
		if c.scene_file_path == "":
			_set_owner(c, root)
