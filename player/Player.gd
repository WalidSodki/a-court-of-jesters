class_name Player
extends CharacterBody2D
## Top-down 8-direction movement with acceleration/deceleration and hold-to-run.
## Only moves while GameState is EXPLORING, so dialogue/menus/cutscenes disable
## control simply by changing the mode — never by poking this script.

@export var walk_speed: float = 55.0
@export var run_speed: float = 95.0
@export var acceleration: float = 700.0
@export var friction: float = 800.0

const SPRITE_BASE_Y := -8.0  # draw the 16px sprite above the feet (origin = feet)

const STEP_DISTANCE := 15.0  # px travelled between footsteps

@onready var sprite: Sprite2D = $Sprite

var _facing := 1.0
var _bob_time := 0.0
var _step_accum := 0.0
var _dust: CPUParticles2D


func _ready() -> void:
	add_to_group("player")
	sprite.position.y = SPRITE_BASE_Y
	_add_glow()
	_add_dust()


## Soft light the jester carries, so exploration reveals the dim hall.
func _add_glow() -> void:
	var light := PointLight2D.new()
	light.texture = Art.light_texture()
	light.texture_scale = 0.6
	light.energy = 0.85
	light.color = Color(1.0, 0.96, 0.86)
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.position = Vector2(0, -6)
	add_child(light)


func _add_dust() -> void:
	_dust = CPUParticles2D.new()
	_dust.amount = 8
	_dust.one_shot = true
	_dust.explosiveness = 1.0
	_dust.lifetime = 0.4
	_dust.emitting = false
	_dust.local_coords = false
	_dust.spread = 45.0
	_dust.direction = Vector2(0, -1)
	_dust.gravity = Vector2(0, 24)
	_dust.initial_velocity_min = 5.0
	_dust.initial_velocity_max = 13.0
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.0
	_dust.color = Color(0.82, 0.76, 0.66, 0.6)
	add_child(_dust)


## Camera shake for impacts/scares (see ShakeCamera).
func shake_camera(amount: float, time: float = 0.3) -> void:
	var cam := $Camera2D
	if cam is ShakeCamera:
		cam.shake(amount, time)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var running := false
	if GameState.is_exploring():
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		running = Input.is_action_pressed("run")

	if input != Vector2.ZERO:
		var target := input * (run_speed if running else walk_speed)
		velocity = velocity.move_toward(target, acceleration * delta)
		if input.x != 0.0:
			_facing = signf(input.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_animate(delta, running)


func _animate(delta: float, running: bool) -> void:
	sprite.flip_h = _facing < 0.0
	var speed := velocity.length()
	if speed > 5.0:
		# Walk bob + squash — cheap juice that sells motion without walk frames.
		_bob_time += delta * (16.0 if running else 10.0)
		var b := sin(_bob_time)
		sprite.position.y = SPRITE_BASE_Y - absf(b) * 1.5
		sprite.scale = Vector2(1.0 + b * 0.04, 1.0 - b * 0.04)
		_step_accum += speed * delta
		if _step_accum >= STEP_DISTANCE:
			_step_accum = 0.0
			_footstep()
	else:
		_bob_time = 0.0
		_step_accum = STEP_DISTANCE  # first move triggers a step promptly
		sprite.position.y = lerpf(sprite.position.y, SPRITE_BASE_Y, delta * 12.0)
		sprite.scale = sprite.scale.lerp(Vector2.ONE, delta * 12.0)


func _footstep() -> void:
	AudioManager.play_sfx(&"footstep", randf_range(0.9, 1.1))
	if _dust != null:
		_dust.restart()
