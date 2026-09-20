class_name Chaser
extends Node2D
## A threat that pursues the player during a flee section. Self-contained: it
## steers straight toward the player and reports how close it is (and a catch)
## via signals — the ChaseController turns those into UI and the caught outcome,
## so the chaser knows nothing about them.
##
## Like everything driven by the control-mode spine, it only chases while
## GameState is EXPLORING; dialogue, menus and the caught cutscene freeze it
## automatically. There is no pathfinding (matching the guards): keep flee rooms
## open so straight-line pursuit reads fair.

signal proximity_changed(level: float)   # 0..1 for THIS chaser (how close it is)
signal caught                            # reached the player

@export var speed: float = 82.0          # just under the player's run_speed (95)
@export var catch_distance: float = 12.0  # px; closer than this = caught
@export var danger_distance: float = 90.0 # px; proximity ramps to 1 within this
@export var start_delay: float = 0.8      # head-start grace before it moves, seconds

const GLOW_COLOR := Color(1.0, 0.2, 0.15)

var _home := Vector2.ZERO
var _facing := Vector2.DOWN
var _proximity := 0.0
var _delay := 0.0
var _caught := false
var _player: Node2D                        # cached; re-fetched only if freed
var _sprite: Sprite2D
var _glow: PointLight2D


func _ready() -> void:
	add_to_group("chaser")
	_home = global_position
	_delay = start_delay
	_sprite = get_node_or_null("Sprite")
	_add_glow()


func get_proximity() -> float:
	return _proximity


## Cached player lookup — avoids a group scan every physics frame.
func _player_node() -> Node2D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player


## Return to start and forget the player (called after a catch).
func reset() -> void:
	global_position = _home
	_facing = Vector2.DOWN
	_proximity = 0.0
	_delay = start_delay
	_caught = false
	_update_visuals()
	proximity_changed.emit(0.0)


func _physics_process(delta: float) -> void:
	if not GameState.is_exploring():
		return
	_pursue(delta)
	_sense()
	_update_visuals()


func _pursue(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	var player := _player_node()
	if player == null:
		return
	var to: Vector2 = player.global_position - global_position
	var dist := to.length()
	if dist < 0.001:
		return
	global_position += to / dist * speed * delta
	_facing = to / dist


func _sense() -> void:
	var player := _player_node()
	if player == null:
		return
	var dist := (player.global_position - global_position).length()
	var prev := _proximity
	# 0 at danger_distance, 1 at the catch point — reads as "how close is it".
	_proximity = clampf(1.0 - (dist - catch_distance) / maxf(danger_distance - catch_distance, 1.0), 0.0, 1.0)
	if not is_equal_approx(_proximity, prev):
		proximity_changed.emit(_proximity)
	if dist <= catch_distance and not _caught:
		_caught = true
		caught.emit()


func _update_visuals() -> void:
	if _sprite != null:
		_sprite.flip_h = _facing.x < 0.0


## A menacing red glow so the threat reads in the dark (reuses the shared light
## texture the player glow uses).
func _add_glow() -> void:
	_glow = PointLight2D.new()
	_glow.texture = Art.light_texture()
	_glow.color = GLOW_COLOR
	_glow.energy = 0.9
	_glow.texture_scale = 0.55
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.position = Vector2(0, -6)
	add_child(_glow)
