extends CharacterBody2D

const SPEED : float = 120.0

enum Dir { DOWN, UP, LEFT, RIGHT }

var _facing : Dir = Dir.DOWN

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_play_idle()


func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)
	if dir != Vector2.ZERO:
		# Prefer the dominant axis — no diagonal movement
		if abs(dir.x) >= abs(dir.y):
			_facing  = Dir.RIGHT if dir.x > 0.0 else Dir.LEFT
			velocity = Vector2(sign(dir.x), 0.0) * SPEED
		else:
			_facing  = Dir.DOWN if dir.y > 0.0 else Dir.UP
			velocity = Vector2(0.0, sign(dir.y)) * SPEED
		_play_walk()
	else:
		velocity = Vector2.ZERO
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
			# idle left has no frames — mirror idle right
			anim.flip_h = true
			anim.play("idle right")
