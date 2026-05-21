extends CharacterBody2D

const SPEED        : float = 150.0
const SPRINT_SPEED : float = 280.0
const SIT_DELAY    : float = 5.0

enum Dir { DOWN, UP, LEFT, RIGHT }

var _facing    : Dir   = Dir.DOWN
var _idle_time : float = 0.0
var _sitting   : bool  = false

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_play_idle()
	var cam := find_child("Camera2D", true, false) as Camera2D
	if cam:
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed   = 8.0


func _physics_process(delta: float) -> void:
	var spd := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	var dir := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"))
		- float(Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")),
		float(Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"))
		- float(Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"))
	)
	if dir != Vector2.ZERO:
		_idle_time = 0.0
		_sitting   = false
		if abs(dir.x) >= abs(dir.y):
			_facing  = Dir.RIGHT if dir.x > 0.0 else Dir.LEFT
			velocity = Vector2(sign(dir.x), 0.0) * spd
		else:
			_facing  = Dir.DOWN if dir.y > 0.0 else Dir.UP
			velocity = Vector2(0.0, sign(dir.y)) * spd
		_play_walk()
	else:
		velocity    = Vector2.ZERO
		_idle_time += delta
		if _idle_time >= SIT_DELAY:
			if not _sitting:
				_sitting = true
				_play_sit()
		elif not _sitting:
			_play_idle()
	move_and_slide()


func _play_walk() -> void:
	anim.flip_h = false
	match _facing:
		Dir.DOWN:  anim.play("walk down")
		Dir.UP:    anim.play("walk up")
		Dir.RIGHT: anim.play("walk right")
		Dir.LEFT:  anim.play("walk left")


func _play_idle() -> void:
	anim.flip_h = false
	match _facing:
		Dir.DOWN:  anim.play("idle down")
		Dir.UP:    anim.play("idle up")
		Dir.RIGHT: anim.play("idle right")
		Dir.LEFT:
			anim.flip_h = true
			anim.play("idle right")


func _play_sit() -> void:
	anim.flip_h = false
	match _facing:
		Dir.DOWN:  anim.play("sit down")
		Dir.UP:    anim.play("sit up")
		Dir.RIGHT: anim.play("sit right")
		Dir.LEFT:
			anim.flip_h = true
			anim.play("sit right")
