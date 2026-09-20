class_name Guard
extends Node2D
## A patrolling guard for stealth sections. Self-contained: it walks a patrol
## path, sweeps a vision cone, and raises a gradual detection meter when it sees
## the player (line-of-sight, blocked by walls). It reports detection/caught via
## signals — the StealthController turns those into UI and the caught outcome, so
## the guard knows nothing about them.
##
## Like everything driven by the control-mode spine, it only patrols and looks
## while GameState is EXPLORING; dialogue, menus and the caught cutscene freeze
## it automatically.

signal detection_changed(level: float)   # 0..1 for THIS guard
signal caught                            # detection reached 1.0

## Patrol waypoints as offsets (px) from the guard's placed position. Fewer than
## two points = a stationary sentry that keeps its starting facing.
@export var patrol_points: PackedVector2Array = PackedVector2Array()
@export var speed: float = 26.0
@export var wait_time: float = 1.0        # pause at each waypoint, seconds
@export var view_distance: float = 74.0
@export var view_angle_deg: float = 70.0  # full cone width
@export var fill_rate: float = 1.5        # detection gained per second while seen
@export var drain_rate: float = 0.9       # detection lost per second while unseen

const CONE_IDLE := Color(1.0, 0.95, 0.4, 0.42)
const CONE_ALARM := Color(1.0, 0.2, 0.15, 0.72)

var _points: Array[Vector2] = []          # resolved global waypoints
var _target := 0
var _dir := 1                             # ping-pong direction
var _wait := 0.0
var _facing := Vector2.DOWN
var _detection := 0.0
var _home := Vector2.ZERO
var _player: Node2D                        # cached; re-fetched only if freed
var _sprite: Sprite2D
var _cone: Polygon2D
var _mark: Label


func _ready() -> void:
	add_to_group("guard")
	_home = global_position
	_sprite = get_node_or_null("Sprite")
	for p in patrol_points:
		_points.append(_home + p)
	_build_cone()
	_build_mark()
	_update_visuals()


func get_detection() -> float:
	return _detection


## Cached player lookup — avoids a group scan every physics frame per guard.
func _player_node() -> Node2D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player


## Return to start and forget the player (called after a catch).
func reset() -> void:
	global_position = _home
	_target = 0
	_dir = 1
	_wait = 0.0
	_detection = 0.0
	_facing = Vector2.DOWN
	_update_visuals()
	detection_changed.emit(0.0)


func _physics_process(delta: float) -> void:
	if not GameState.is_exploring():
		return
	_patrol(delta)
	_sense(delta)
	_update_visuals()


func _patrol(delta: float) -> void:
	if _points.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		return
	var to: Vector2 = _points[_target] - global_position
	var dist := to.length()
	if dist <= 1.0:
		_wait = wait_time
		_advance_target()
		return
	global_position += to / dist * speed * delta
	_facing = to / dist


func _advance_target() -> void:
	_target += _dir
	if _target >= _points.size():
		_target = _points.size() - 2
		_dir = -1
	elif _target < 0:
		_target = 1
		_dir = 1


func _sense(delta: float) -> void:
	var prev := _detection
	if _can_see_player():
		_detection = clampf(_detection + fill_rate * delta, 0.0, 1.0)
	else:
		_detection = clampf(_detection - drain_rate * delta, 0.0, 1.0)
	if not is_equal_approx(_detection, prev):
		detection_changed.emit(_detection)
	if _detection >= 1.0 and prev < 1.0:
		caught.emit()


func _can_see_player() -> bool:
	var player := _player_node()
	if player == null:
		return false
	var to: Vector2 = player.global_position - global_position
	var dist := to.length()
	if dist > view_distance or dist < 0.001:
		return false
	if absf(rad_to_deg(_facing.angle_to(to))) > view_angle_deg * 0.5:
		return false
	# Line of sight: a wall (physics layer 1) between us breaks the view. Exclude
	# the player itself, whose body also sits on layer 1, so only walls can block.
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	if player is CollisionObject2D:
		q.exclude = [(player as CollisionObject2D).get_rid()]
	return space.intersect_ray(q).is_empty()


# --- Visuals (readable threat + juice) ---------------------------------------

func _update_visuals() -> void:
	if _sprite != null:
		_sprite.flip_h = _facing.x < 0.0
	if _cone != null:
		_cone.rotation = _facing.angle()
		_cone.color = CONE_IDLE.lerp(CONE_ALARM, _detection)
	if _mark != null:
		if _detection >= 0.75:
			_mark.text = "!"
			_mark.modulate = Color(1, 0.3, 0.25)
			_mark.visible = true
		elif _detection >= 0.25:
			_mark.text = "?"
			_mark.modulate = Color(1, 0.9, 0.4)
			_mark.visible = true
		else:
			_mark.visible = false


func _build_cone() -> void:
	_cone = Polygon2D.new()
	var pts := PackedVector2Array([Vector2.ZERO])
	var half := deg_to_rad(view_angle_deg * 0.5)
	var steps := 10
	for i in steps + 1:
		var a := -half + (2.0 * half) * i / float(steps)
		pts.append(Vector2(cos(a), sin(a)) * view_distance)
	_cone.polygon = pts
	_cone.color = CONE_IDLE
	add_child(_cone)
	move_child(_cone, 0)   # draw behind the guard sprite, but above the floor


func _build_mark() -> void:
	_mark = Label.new()
	_mark.add_theme_font_size_override("font_size", 10)
	_mark.add_theme_color_override("font_outline_color", Color.BLACK)
	_mark.add_theme_constant_override("outline_size", 3)
	_mark.position = Vector2(-2, -24)
	_mark.visible = false
	add_child(_mark)
